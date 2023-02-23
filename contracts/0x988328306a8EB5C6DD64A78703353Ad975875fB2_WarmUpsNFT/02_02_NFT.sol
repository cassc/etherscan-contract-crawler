// SPDX-License-Identifier: MIT

/// @title WarmUps


pragma solidity ^0.8.6;


// .-.  .-. .--. ,---.            .-. .-.,---.   .---. 
// | |/\| |/ /\ \| .-.\  |\    /| | | | || .-.\ ( .-._)
// | /  \ / /__\ \ `-'/  |(\  / | | | | || |-' |_) \   
// |  /\  |  __  |   (   (_)\/  | | | | || |--'_  \ \  
// |(/  \ | |  |)| |\ \  | \  / | | `-')|| |  ( `-'  ) 
// (_)   \|_|  (_)_| \)\ | |\/| | `---(_)/(    `----'  
//                   (__)'-'  '-'       (__)           


import { IERC721, ERC721, Ownable } from './FlatDependencies.sol';

contract WarmUpsNFT is IERC721, Ownable, ERC721 {

  uint256 public constant PRICE = 0.069 ether;

  uint8 public constant MAX_SUPPLY = 222;

  uint8 public constant MAX_MINT_PER_WALLET = 5;

  uint8 public mint_index = 1;

  mapping(address => uint8) public minters;

  string public baseURI = "https://harlequin-rapid-barnacle-766.mypinata.cloud/ipfs/QmZHkRNPKhwkAuZPWShp8jycmWpXJfrfRQ2TWLb2vqUine/";

  bool public mintOpen;

  constructor() ERC721('WarmUpsNFT', 'WarmUpsNFT') {
    mintOpen = false;
  }

  /// @notice Public mints
  function mint(uint8 amount) public payable {

    /// @notice Cannot exceed maximum supply
    require(mint_index + amount <= MAX_SUPPLY, "WarmUpsNFT: Not enough mints remaining");

    /// @notice public can mint mint a maximum quantity at a time.
    require(amount <= MAX_MINT_PER_WALLET, 'WarmUpsNFT: mint amount exceeds maximum');

    /// @notice public must send in correct funds
    require(msg.value > 0 && msg.value == amount * PRICE, "WarmUpsNFT: Not enough value sent");

    /// @notice checks amount already minted
  require(minters[_msgSender()]  + amount <= MAX_MINT_PER_WALLET, "WarmUpsNFT: cannot exceed max mint amount");

    require(mintOpen == true, "WarmUpsNFT: mint has not opened");

    _mintAmountTo(_msgSender(), amount, mint_index);

    mint_index += amount;
    minters[_msgSender()] += amount;

  }

  function teamMint(uint8 amount, address recipient) public onlyOwner {

    /// @notice Cannot exceed maximum supply
    require(mint_index + amount <= MAX_SUPPLY, "WarmUpsNFT: Not enough mints remaining");

    /// @notice public can mint mint a maximum quantity at a time.
    require(amount <= MAX_MINT_PER_WALLET, 'WarmUpsNFT: mint amount exceeds maximum');

    /// @notice checks amount already minted
     require(minters[recipient] + amount <= MAX_MINT_PER_WALLET, "WarmUpsNFT: already minted max amount");


    _mintAmountTo(recipient, amount, mint_index);

    mint_index += amount;
    minters[recipient] += amount;

  }

  function _mintAmountTo(address to, uint8 amount, uint8 startId) internal {
    for (uint8 i = startId; i < startId + amount; i++){
      _mint(to, i);
    }
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function _baseURI() internal override view returns (string memory){
    return baseURI;
  }

  function toggleMint(bool mintStatus) external onlyOwner {
    mintOpen = mintStatus;
  }

  /**
   * @notice returns token ids owned by a owner, don't use this onchain
   */
  function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
      uint256 tokenCount = balanceOf(_owner);
      if (tokenCount == 0) {
          return new uint256[](0);
      } else {
          unchecked {
              uint256[] memory result = new uint256[](tokenCount);
              uint256 index;
              uint256 i = 1;
              for (i; i < MAX_SUPPLY; i++) {
                  if (ownerOf(i) == _owner) {
                      result[index] = i;
                      index++;
                  }
              }
              return result;
          }
      }
  }

  /**
   * @notice returns token ids batched owned by a owner, don't use this onchain
   */
  function tokensOfOwnerBatched(
      address _owner,
      uint256 _start,
      uint256 _stop
  ) external view returns (uint16[] memory) {
      if (_stop > MAX_SUPPLY) _stop = MAX_SUPPLY;
      uint256 balance = balanceOf(_owner);
      uint16[] memory tokens = new uint16[](balance);
      uint256 index;
      for (uint256 i = _start; i <= _stop; ) {
          unchecked {
              if (ownerOf(i) == _owner) {
                  tokens[index] = uint16(i);
                  index++;
              }
              i++;
          }
      }

      return tokens;
  }

  /**
   * @notice returns token ids owned by a owner, don't use this onchain
   */
  function ownersOfTokens() external view returns (address[] memory) {
      address[] memory owners = new address[](mint_index);
      unchecked {
          for (uint256 i = 1; i <= mint_index; i++) {
              owners[i - 1] = ownerOf(i);
          }
      }
      return owners;
  }

  /**
   * @notice returns token ids batched owned by a owner, don't use this onchain
   */
  function ownersOfTokensBatched(uint256 _start, uint256 _stop) external view returns (address[] memory) {
      if (_stop > mint_index) _stop = mint_index;
      address[] memory owners = new address[](mint_index);
      for (uint256 i = _start; i <= _stop; ) {
          unchecked {
              owners[i - _start] = ownerOf(i);
              i++;
          }
      }

      return owners;
  }

  /// @notice Sends balance of this contract to owner
  function withdraw() public onlyOwner {
    (bool success, ) = owner().call{value: address(this).balance}("");
    require(success, "WarmUpsNFT: Withdraw unsuccessful");
  }
}