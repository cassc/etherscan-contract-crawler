// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import "IERC721Enumerable.sol";

interface IXfaiINFT is IERC721Enumerable {
  function reserve() external view returns (uint);

  function totalSharesIssued() external view returns (uint);

  function initialReserve() external view returns (uint);

  function harvestedBalance(address _token) external view returns (uint);

  function INFTShares(uint _id) external view returns (uint);

  function sharesHarvestedByPool(address _token, uint _id) external view returns (uint);

  function totalSharesHarvestedByPool(address _token) external view returns (uint);

  function setBaseURI(string memory _baseURI) external;

  function getStates() external view returns (uint, uint, uint);

  function shareToTokenAmount(
    uint _tokenID,
    address _token
  ) external view returns (uint share2amount, uint inftShare, uint harvestedShares);

  function premint(address[] memory _legacyLNFTHolders, uint[] memory _initialShares) external;

  function mint(address _to) external returns (uint tokenID, uint share);

  function boost(uint _tokenID) external returns (uint share);

  function harvestToken(address _token, uint _tokenID, uint _amount) external returns (uint);

  function harvestETH(uint _tokenID, uint _amount) external returns (uint);

  event Mint(address indexed from, address indexed to, uint share, uint id);
  event Boost(address indexed from, uint share, uint id);
  event HarvestToken(address token, uint harvestedAmount, uint harvestedShare, uint id);
  event HarvestETH(uint harvestedAmount, uint harvestedShare, uint id);
}