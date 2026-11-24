/* global axios */

const URL = '/api/v1/profile/outlook';

export default {
  show: () => axios.get(URL),
  authorize: () => axios.post(`${URL}/authorization`),
  messages: folder => axios.get(`${URL}/messages`, { params: { folder } }),
  disconnect: () => axios.delete(URL),
};
