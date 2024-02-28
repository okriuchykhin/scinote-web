<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block" id="edit-project-modal-label">
              {{ i18n.t('projects.index.modal_new_project.modal_title') }}
            </h4>
          </div>
          <div class="modal-body">
            <div class="mb-6">
              <label class="sci-label">{{ i18n.t("projects.index.modal_new_project.name") }}</label>
              <div class="sci-input-container-v2" :class="{'error': error}" :data-error="error">
                <input type="text" v-model="name"
                       class="sci-input-field"
                       ref="input"
                       autofocus="true"
                       :placeholder="i18n.t('projects.index.modal_new_project.name_placeholder')" />
              </div>
            </div>
            <div class="flex gap-2 text-xs items-center">
              <div class="sci-checkbox-container">
                <input type="checkbox" class="sci-checkbox" v-model="visible" value="visible"/>
                <span class="sci-checkbox-label"></span>
              </div>
              <span v-html="i18n.t('projects.index.modal_new_project.visibility_html')"></span>
            </div>
            <div class="mt-6" :class="{'hidden': !visible}">
              <label class="sci-label">{{ i18n.t("user_assignment.select_default_user_role") }}</label>
              <SelectDropdown :optionsUrl="userRolesUrl" :value="defaultRole" @change="changeRole" />
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
            <button class="btn btn-primary" type="submit">
              {{ i18n.t('projects.index.modal_new_project.create') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>

import SelectDropdown from '../../shared/select_dropdown.vue';
import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin';

export default {
  name: 'NewProjectModal',
  props: {
    createUrl: String,
    userRolesUrl: String,
    currentFolderId: String,
  },
  mixins: [modalMixin],
  components: {
    SelectDropdown,
  },
  data() {
    return {
      name: '',
      visible: false,
      defaultRole: null,
      error: null,
      disableSubmit: false
    };
  },
  methods: {
    submit() {
      this.disableSubmit = true;
      axios.post(this.createUrl, {
        project: {
          name: this.name,
          visibility: (this.visible ? 'visible' : 'hidden'),
          default_public_user_role_id: this.defaultRole,
          project_folder_id: this.currentFolderId,
        },
      }).then(() => {
        this.error = null;
        this.$emit('create');
      }).catch((error) => {
        this.error = error.response.data.name;
      });
      this.disableSubmit = false;
    },
    changeRole(role) {
      this.defaultRole = role;
    },
  },
};
</script>