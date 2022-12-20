// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IERC1155Token.sol";
import "./IAllowlist.sol";

interface IPropsCreatorConfig is IERC1155Token {

   struct Split{
        address[] accounts;
        uint32[] percentAllocations;
        uint32 distributorFee;
     }

   struct CreateMintConfig{
        string _configuration;
        uint256 _quantity;
        uint256 _price; 
        string _nonce;
        bytes _signature;
        uint256 _issuedOn;
    }

  struct SignatureRequest{
        string tokenCheck;
        string primaryCheck;
        string royaltyCheck;
        string configuration;
        uint256 quantity;
        uint256 price;
        string nonce;
        uint256 issuedOn;
        bytes signature;
    }

  struct MintCart{
        uint256 _cost;
        uint256 _quantity;
        string _tokensMinted;
    }

  struct AllocationCheck{
    IAllowlist.Allowlist allowlist;
    address _address;
    uint256 _minted;
    uint256 _quantity;
    uint256 _alloted;
    bytes32[] _proof;
  }

  
  function getSignatureVerifier() external view returns (address);
  function getSplitMain() external view returns (address);
  function isUniqueArray(uint256[] calldata _array) external pure returns (bool);
  function getTokenCheck(ERC1155Token memory _token) external view returns (string memory);
  function getPrimaryCheck(Split memory _primarySplit) external view returns (string memory);
  function getRoyaltyCheck(Split memory _royaltySplit) external view returns (string memory);
  function getCreationCheck(IPropsCreatorConfig.ERC1155Token memory _token, IPropsCreatorConfig.Split memory _primarySplit, IPropsCreatorConfig.Split memory _royaltySplit) external view returns(string memory, string memory, string memory);
  function setTokenRoyalty(uint256 _tokenId, address _royaltyReceiver, uint96 _royaltyPercentage) external;
  function upsertToken(ERC1155Token memory _token, Split memory _primarySplit, Split memory _royaltySplit, bool _updateSplits) external returns (ERC1155Token memory);
  function getToken(uint256 _tokenId) external view returns (ERC1155Token memory);
  function revertOnUnauthorizedSignature(SignatureRequest calldata _inputs ) external view;
  function isOperatorBlocked(address _operatorAddress) external view returns (bool);
  function getDisallowedOperatorMessage(address _operatorAddress) external view returns (string memory);
  function getIPFSAt() external view returns (uint256);
  function getBaseURI() external view returns (string memory);
  function getTokenURI(uint256 _tokenId) external view returns (string memory);
  function isSanctioned(address _operatorAddress) external view returns (bool);
  function isValidMinter(address _operatorAddress, uint256[] calldata _array) external view returns (bool);
  function packMintString(string memory _string1, string memory _string2, string memory _string3,string memory _string4,string memory _string5) external pure returns (string memory);
  function revertOnAllocationCheckFailure(AllocationCheck calldata check) external view;
  function updateOwnership(address from, address to, uint256[] memory tokenIds, uint256[] memory amounts) external;
  function balanceOf(address owner) external view returns (uint256);
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
  function totalSupply(uint256 id) external view returns (uint256);
  function getTokenSupply(uint256 _tokenId) external returns (uint256);
  
  struct betaCheck{
    uint256 betaTokens;
    uint256 betaMints;
    uint256 cartMints;
  }

}