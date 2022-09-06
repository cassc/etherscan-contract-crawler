interface IRenCrvArbitrum {
  function exchange(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy,
    address recipient
  ) external returns (uint256);
}