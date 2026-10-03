(function initializeProfileStorage(global) {
  let nativeReadyPromise;

  const serviceToken = new URLSearchParams(global.location.search).get("ymboxToken");
  async function profileRequest(action, payload = {}) {
    try {
      const response = await fetch(`/api/profiles/${action}`, {method:"POST", headers:{"Content-Type":"application/json", "X-YMBOX-Token":serviceToken}, body:JSON.stringify(payload)});
      const result = await response.json();
      return response.ok ? result : {ok:false,error:result.error || "方案服务请求失败"};
    } catch (error) { return {ok:false,error:`方案服务不可用：${error.message}`}; }
  }
  const serviceApi = {
    list_profiles: kind => profileRequest("list", {kind}),
    load_profile: (kind, name) => profileRequest("load", {kind, name}),
    save_profile: (kind, name, data) => profileRequest("save", {kind, name, data}),
    get_storage_info: () => profileRequest("info"),
  };

  function waitForNativeApi() {
    if (global.pywebview && global.pywebview.api) {
      return Promise.resolve(global.pywebview.api);
    }
    if (serviceToken && global.location.protocol === "http:") return Promise.resolve(serviceApi);

    if (!nativeReadyPromise) {
      nativeReadyPromise = new Promise((resolve) => {
        let settled = false;
        const finish = () => {
          if (settled) return;
          settled = true;
          resolve(global.pywebview && global.pywebview.api ? global.pywebview.api : null);
        };
        global.addEventListener("pywebviewready", finish, { once: true });
        global.setTimeout(finish, 500);
      });
    }

    return nativeReadyPromise;
  }

  function unavailable() {
    return {
      ok: false,
      error: "JSON 方案服务不可用。请通过“启动YMBOX配置工具.pyw”打开工具。",
    };
  }

  async function list(kind) {
    const api = await waitForNativeApi();
    return api ? api.list_profiles(kind) : {...unavailable(), profiles: []};
  }

  async function save(kind, name, data) {
    const api = await waitForNativeApi();
    const result = api ? await api.save_profile(kind, name, data) : unavailable();

    if (result.ok) {
      global.dispatchEvent(new CustomEvent("ymbox:profile-saved", { detail: { kind, name: result.name } }));
    }
    return result;
  }

  async function load(kind, name) {
    const api = await waitForNativeApi();
    return api ? api.load_profile(kind, name) : unavailable();
  }

  async function getInfo() {
    const api = await waitForNativeApi();
    return api ? api.get_storage_info() : unavailable();
  }

  global.YMBOXProfiles = Object.freeze({ list, save, load, getInfo });
})(window);
