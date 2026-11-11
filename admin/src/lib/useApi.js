import { useEffect, useState } from 'react';
import { api } from './api';
export default function useApi(path) {
  const [revision, setRevision] = useState(0);
  const requestKey = `${path}:${revision}`;
  const [result, setResult] = useState(null);
  useEffect(() => {
    const controller = new AbortController();
    api(path, { signal: controller.signal }).then(data => {
      if (!controller.signal.aborted) setResult({ key: requestKey, data, loading: false, error: '' });
    }).catch(error => {
      if (!controller.signal.aborted) setResult({ key: requestKey, data: null, loading: false, error: error.message });
    });
    return () => controller.abort();
  }, [path, requestKey]);
  const state = result?.key === requestKey ? result : { data: null, loading: true, error: '' };
  return { ...state, reload: () => setRevision(value => value + 1) };
}
