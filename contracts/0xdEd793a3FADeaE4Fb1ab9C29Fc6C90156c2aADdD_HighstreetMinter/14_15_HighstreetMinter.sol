// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./HighstreetAssets.sol";

contract HighstreetMinter is Context, Ownable {

  /// @dev Link to HIGH STREET HOME ERC721 instance
  address public immutable NFT;

  struct InputArgs {
    address receiver;
    uint256 id;
    uint256 amount;
  }

  /**
    * @dev Fired in mintBatch()
    *
    * @param to an address which received nfts
    * @param id an number represented a specific id which is minted
    * @param amount a number represented numbers of amount which id to mint
    */
  event MintBatch(address indexed to, uint256 indexed id, uint256 indexed amount);

  /**
   * @dev constructor function
   *
   * @param nft_ HighStreetHome ERC721 instance address
   */
  constructor (
    address nft_
  ) {
    require(nft_ != address(0), 'invalid nft address');
    NFT = nft_;
  }

  /**
    * @notice Service function to mint nfts at same time
    *
    * @dev this function can only be called by minters
    *
    * @param args an array of object which instance of InputArgs
    */
  function mintBatch(InputArgs[] memory args ) external onlyOwner {

    HighstreetAssets assets = HighstreetAssets(NFT);
    require(assets.minters(address(this)) == true, "not minter role");

    for(uint256 index = 0; index < args.length; index ++) {
      address receiver = args[index].receiver;
      uint256 id = args[index].id;
      uint256 amount = args[index].amount;
      require(receiver != address(0), 'invalid receiver');
      assets.mint(receiver, id, amount, '0x');
      emit MintBatch(receiver, id, amount);
    }
  }
}