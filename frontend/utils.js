const percentToProportion = percent => {
  const { num, denom } = bigRat(percent).divide(100);
  return { num: num.toString(), denom: denom.toString() };
};
const getURLSearchParam = param =>
  new URLSearchParams(location.search.slice(1)).get(param); // refactor
