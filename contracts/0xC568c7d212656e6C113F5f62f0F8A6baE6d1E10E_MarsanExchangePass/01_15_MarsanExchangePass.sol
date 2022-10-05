// SPDX-License-Identifier: MIT
// Thanks to @charged-particles for ERC721i

/* __  __                              _____          _                            
/ |  \/  | __ _ _ __ ___  __ _ _ __   | ____|_  _____| |__   __ _ _ __   __ _  ___ 
/ | |\/| |/ _` | '__/ __|/ _` | '_ \  |  _| \ \/ / __| '_ \ / _` | '_ \ / _` |/ _ \
/ | |  | | (_| | |  \__ \ (_| | | | | | |___ >  < (__| | | | (_| | | | | (_| |  __/
/ |_|  |_|\__,_|_|  |___/\__,_|_| |_| |_____/_/\_\___|_| |_|\__,_|_| |_|\__, |\___|
/                                                                       |___/      */

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@charged-particles/erc721i/contracts/ERC721i.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// ERC721i Contract
contract MarsanExchangePass is ERC721i, ReentrancyGuard {
  using Address for address payable;
  using Strings for uint256;

  /// @dev Events
  event Withdraw(address indexed receiver, uint256 amount);

  /// @dev IPFS image for onchain metadata use. 
  string private baseImg = "ipfs://QmTdawCAV4hydZ85upPzS4zoabpFuCrbdTgiYrdTGt25p5";
  /// @dev IPFS video for onchain metadata use.
  string private baseAnim = "ipfs://QmPcSsWm3CfL7zjGWzAegkK8ePjR9LfTF5JjXCte9ffxTk";
  /// @dev IPFS tokenURI for offchain metadata
  string private baseURI = "ipfs://QmZ2mp14MBnYN9mVCsu1wK5CeuopVNqgkTCqSF6bmWsPSh";
  /// @dev onchainData state. Will be using on-chain metadata by default
  bool public useOnChainMetadata = true;

  error NonExistentTokenURI();

  /// @dev The Deployer of this contract is also the Owner and the Pre-Mint Receiver.
  constructor(
    string memory name,
    string memory symbol,
    uint256 maxSupply
  )
    ERC721i(name, symbol, _msgSender(), maxSupply)
  {
    // Since we pre-mint to "owner", allow this contract to transfer on behalf of "owner" for sales.
    _setApprovalForAll(_msgSender(), address(this), true);
  }

  /// @dev Premint the NFT based on maxSupply
  function preMint() external onlyOwner {
    _preMint();
  }

  /// @dev Set the baseURI / json file from IPFS
  function setBaseURI(string calldata _baseURI) external onlyOwner {
    baseURI = _baseURI;
  }

  /// @dev Set the baseImg / image file from IPFS
  function setBaseImg(string memory _baseImg) external onlyOwner {
    baseImg = _baseImg;
  }

  /// @dev Set the baseAnim / video file from IPFS
  function setBaseAnim(string memory _baseAnim) external onlyOwner {
    baseAnim = _baseAnim;
  }

  /// @dev Set to use on-chain metadata or ol good IPFS metadata
  function useOnChainData(bool _state) external onlyOwner {
    useOnChainMetadata = _state;
  }

  /// @dev Withdraw ETH from Contract
  function withdraw() external onlyOwner {
    uint256 amount = address(this).balance;
    address payable receiver = payable(owner());
    receiver.sendValue(amount);
    emit Withdraw(receiver, amount);
  }

  /// @dev Override the tokenURI 
  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    if (ownerOf(_tokenId) == address(0)) revert NonExistentTokenURI();
    // Check if using on-chain metadata or not
    if (!useOnChainMetadata) {
      // Return the baseURI
      return baseURI;
    }
    // Return the on-chain metadata
    return getMetadata();
  }

  /// @dev Generate the metadata on chain
  function getMetadata() internal view returns (string memory) {

    string memory output;
    // Metadata start here. Refer metadata standard here : https://docs.opensea.io/docs/metadata-standards
    string memory _name = "Marsan Exchange Pass";
    string memory _desc = "To join, one must hold the Marsan Exchange Pass NFT. Membership includes access to our private Discord, in-person events, and other collaborations created exclusively for Marsan Exchange pass holders.";
    string memory _image = baseImg;
    string memory _animURL = baseAnim;
    string memory _extURL = "\"external_url\": \"https://marsanexchange.com\"";
    string memory _attributes = "\"attributes\": [{\"trait_type\": \"Type\",\"value\": \"Marsan Exchange Pass\"}]";

    string memory json = Base64.encode(bytes(string(abi.encodePacked("{\"name\": \"",_name, "\", \"description\": \"", _desc ,"\", \"image\": \"", _image, "\", \"animation_url\": \"", _animURL , "\",", _extURL,",",_attributes,"}"))));
    output = string(abi.encodePacked("data:application/json;base64,", json));

    delete _name; delete _desc; delete _image; delete _animURL; delete _extURL; delete _attributes;
    
    return output;
  }

  // Batch Transfers
  function batchTransfer(
    address to,
    uint256[] memory tokenIds
  ) external virtual returns (uint256 amountTransferred) {
    amountTransferred = _batchTransfer(_msgSender(), to, tokenIds);
  }

  function batchTransferFrom(
    address from,
    address to,
    uint256[] memory tokenIds
  ) external virtual returns (uint256 amountTransferred) {
    amountTransferred = _batchTransfer(from, to, tokenIds);
  }

  function _batchTransfer(
    address from,
    address to,
    uint256[] memory tokenIds
  )
    internal
    virtual
    returns (uint256 amountTransferred)
  {
    uint256 count = tokenIds.length;

    for (uint256 i = 0; i < count; i++) {
      uint256 tokenId = tokenIds[i];

      // Skip invalid tokens; no need to cancel the whole tx for 1 failure
      // These are the exact same "require" checks performed in ERC721.sol for standard transfers.
      if (
        (ownerOf(tokenId) != from) ||
        (!_isApprovedOrOwner(from, tokenId)) ||
        (to == address(0))
      ) { continue; }

      _beforeTokenTransfer(from, to, tokenId);

      // Clear approvals from the previous owner
      _approve(address(0), tokenId);

      amountTransferred += 1;
      _owners[tokenId] = to;

      emit Transfer(from, to, tokenId);

      _afterTokenTransfer(from, to, tokenId);
    }

    // We can save a bit of gas here by updating these state-vars atthe end
    _balances[from] -= amountTransferred;
    _balances[to] += amountTransferred;
  }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}