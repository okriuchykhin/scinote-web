<template>
<div class="content-pane flexible label-templates-show">
  <div class="content-header">
    <div id="breadcrumbsWrapper">
      <div class="breadcrumbs-container">
        <a :href="labelTemplatesUrl" class="breadcrumbs-link">
          {{ i18n.t('label_templates.show.breadcrumb_index') }}
        </a>
        <span class="delimiter">/</span>
      </div>
    </div>
    <div v-if="labelTemplate.id" class="title-row">
      <img :src="labelTemplate.attributes.icon_url" class="label-template-icon"/>
      <InlineEdit
        :value="labelTemplate.attributes.name"
        :characterLimit="255"
        :allowBlank="false"
        :attributeName="i18n.t('label_templates.show.name_error_prefix')"
        :autofocus="editingName"
        :editOnload="newLabel"
        @editingEnabled="editingName = true"
        @editingDisabled="editingName = false"
        @update="updateName"
      />
    </div>
  </div>
  <div id="content-label-templates-show">
    <div v-if="labelTemplate.id" class="template-descripiton">
      <div class="title">
        {{ i18n.t('label_templates.show.description_title') }}
      </div>
      <InlineEdit
        :value="labelTemplate.attributes.description"
        :characterLimit="255"
        :allowBlank="true"
        :attributeName="i18n.t('label_templates.show.description_error_prefix')"
        :placeholder="i18n.t('label_templates.show.description_placeholder')"
        :autofocus="editingDescription"
        @editingEnabled="editingDescription = true"
        @editingDisabled="editingDescription = false"
        @update="updateDescription"
      />
    </div>

    <div v-if="labelTemplate.id" class="label-template-container">
      <div class="label-edit-container">
        <div class="label-edit-header">
          <div class="title">
            {{ i18n.t('label_templates.show.content_title', { format: labelTemplate.attributes.language_type.toUpperCase() }) }}
          </div>
          <InsertFieldDropdown :labelTemplate="labelTemplate"
                               @insertField="insertField"
           />
        </div>
        <template v-if="editingContent">
          <div class="label-textarea-container">
            <textarea
              ref="contentInput"
              v-model="newContent"
              class="label-textarea"
              @blur="updateContent"
            ></textarea>
          </div>
          <div class="button-container">
            <div class="btn btn-secondary refresh-preview">
              <i class="fas fa-sync"></i>
              {{ i18n.t('label_templates.show.buttons.refresh') }}
            </div>
            <div class="btn btn-secondary" @click="editingContent = false">
              {{ i18n.t('general.cancel') }}
            </div>
            <div class="btn btn-primary save-template" @click="updateContent">
              <i class="fas fa-save"></i>
              {{ i18n.t('label_templates.show.buttons.save') }}
            </div>
          </div>
        </template>
        <div v-else class="label-view-container" :title="i18n.t('label_templates.show.view_content_tooltip')" @click="enableContentEdit">{{ labelTemplate.attributes.content}}
          <i class="fas fa-pen"></i>
        </div>
      </div>

      <div class="label-preview-container">
        <LabelPreview :zpl='labelTemplate.attributes.content' :previewUrl="previewUrl" />
      </div>
    </div>
  </div>
</div>
</template>

 <script>

 import InlineEdit from 'vue/shared/inline_edit.vue'
 import InsertFieldDropdown from 'vue/label_template/insert_field_dropdown.vue'
 import LabelPreview from './components/label_preview.vue'

  export default {
    name: 'LabelTemplateContainer',
    props: {
      labelTemplateUrl: String,
      labelTemplatesUrl: String,
      previewUrl: String,
      newLabel: Boolean
    },
    data() {
      return {
        labelTemplate: {
          attributes: {}
        },
        editingName: false,
        editingDescription: false,
        editingContent: false,
        newContent: '',
        cursorPos: 0
      }
    },
    components: {InlineEdit, InsertFieldDropdown, LabelPreview},
    created() {
      $.get(this.labelTemplateUrl, (result) => {
        this.labelTemplate = result.data
        this.newContent = this.labelTemplate.attributes.content
      })
    },
    methods: {
      enableContentEdit() {
        this.editingContent = true
        this.$nextTick(() => {
          this.$refs.contentInput.focus();
          $(this.$refs.contentInput).prop('selectionStart', this.cursorPos)
          $(this.$refs.contentInput).prop('selectionEnd', this.cursorPos)
        });
      },
      updateName(newName) {
        $.ajax({
          url: this.labelTemplate.attributes.urls.update,
          type: 'PATCH',
          data: {label_template: {name: newName}},
          success: (result) => {
            this.labelTemplate.attributes.name = result.data.attributes.name
          }
        });
      },
      updateDescription(newDescription) {
        $.ajax({
          url: this.labelTemplate.attributes.urls.update,
          type: 'PATCH',
          data: {label_template: {description: newDescription}},
          success: (result) => {
            this.labelTemplate.attributes.description = result.data.attributes.description
          }
        });
      },
      updateContent() {
        this.cursorPos = $(this.$refs.contentInput).prop('selectionStart')
        $.ajax({
          url: this.labelTemplate.attributes.urls.update,
          type: 'PATCH',
          data: {label_template: {content: this.newContent}},
          success: (result) => {
            this.labelTemplate.attributes.content = result.data.attributes.content
            this.editingContent = false
          }
        });
      },
      insertField(field) {
        this.enableContentEdit();
        let textBefore = this.newContent.substring(0,  this.cursorPos);
        let textAfter  = this.newContent.substring(this.cursorPos, this.newContent.length);
        this.newContent = textBefore + field + textAfter;
        this.cursorPos = this.cursorPos + field.length;
      }
    }
  }
 </script>