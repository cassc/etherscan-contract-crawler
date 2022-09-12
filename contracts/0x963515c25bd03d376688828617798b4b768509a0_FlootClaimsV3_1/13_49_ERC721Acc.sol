// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./FlootClaimV3P.sol";

contract Accounting721 is Ownable {
    event LuckyHolder(uint256 indexed luckyHolder, address indexed sender);
    event ChosenHolder(uint256 indexed chosenHolder, address indexed sender);

    FlootClaimsV3 _claimContract;

    struct NFTClaimInfo {
      address nftContract;
      uint256 tokenID;
      uint256 holder;
      bool claimed;
    }
    mapping (uint256 => NFTClaimInfo[]) public nftClaimInfo;

    constructor(){
    }

    modifier onlyClaimContract() { // Modifier
        require(
            msg.sender == address(_claimContract),
            "Only Claim contract can call this."
        );
        _;
    }

  function random721(address nftContract, uint256 tokenID) external onlyClaimContract {
    uint256 luckyFuck = _pickLuckyHolder();
    NFTClaimInfo memory newClaim = NFTClaimInfo(nftContract, tokenID, luckyFuck, false);
    nftClaimInfo[luckyFuck].push(newClaim);
    emit LuckyHolder(luckyFuck, nftContract);
  }

  function send721(address nftContract, uint256 tokenID, uint256 chosenHolder) public {
    require(chosenHolder > 0 && chosenHolder <= 11111, "That Doji ID is does not exist");
    ERC721(nftContract).safeTransferFrom(msg.sender,address(_claimContract),tokenID, 'true');
    NFTClaimInfo memory newClaim = NFTClaimInfo(nftContract, tokenID, chosenHolder, false);
    nftClaimInfo[chosenHolder].push(newClaim);
    emit ChosenHolder(chosenHolder, nftContract);
  }

	function _pickLuckyHolder() private view returns (uint) {
		uint256 rando = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _claimContract.currentBaseTokensHolder())));
		uint index = (rando % _claimContract.currentBaseTokensHolder());
		uint result = IERC721Enumerable(_claimContract.baseTokenAddress()).tokenByIndex(index);
		return result;
	}

    function viewNFTsPending(uint id)view external returns (NFTClaimInfo[] memory) {
      return nftClaimInfo[id];
    }

    function viewNFTsPendingByIndex(uint id, uint index)view external returns (NFTClaimInfo memory) {
      return nftClaimInfo[id][index];
    }

    function viewNumberNFTsPending(uint id) view external returns (uint) {
      return nftClaimInfo[id].length;
    }

    function viewNumberNFTsPendingByAcc(address account) public view returns(uint256){
      BaseToken baseToken = BaseToken(_claimContract.baseTokenAddress());
      uint256[] memory userInventory = baseToken.walletInventory(account);
      uint256 pending;

      // get pending payouts for all tokenids in caller's wallet
      for (uint256 index = 0; index < userInventory.length; index++) {
          for(uint256 j = 0; j < nftClaimInfo[userInventory[index]].length; j++) {
              if (nftClaimInfo[userInventory[index]][j].claimed == false) {
                  pending++;
              }
          }
      }
      return pending;
    }

    function claimNft(uint id, uint index) external onlyClaimContract {
      require(msg.sender == address(_claimContract));
      nftClaimInfo[id][index].claimed = true;
    }

    function setClaimProxy (address proxy) public onlyOwner {
      _claimContract = FlootClaimsV3(payable(proxy));
    }
}