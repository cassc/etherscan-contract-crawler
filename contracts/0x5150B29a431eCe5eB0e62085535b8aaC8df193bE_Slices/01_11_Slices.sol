// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./openzeppelin/token/ERC1155/ERC1155.sol"; 
import "./openzeppelin/utils/Strings.sol";
import "./openzeppelin/access/Ownable.sol";

contract Slices is ERC1155, Ownable {

  address public mDev;
  string public mName;
  string public mSymbol;

  string public mContractURI;
  string public mBaseURI;

  struct Subcollection {
    uint startingTokenId;
    uint numPrimaryTokens;
    uint price;
    uint maxPerWallet;
    bool active;
    uint totalTime;
    uint fallbackTime;
    uint startTime;
  }

  mapping(uint => Subcollection) public mAllSubcollections;
  mapping(uint => mapping(address => uint)) public mMintedPerWallet;
  uint public mNextSubcollectionId;
  uint public mNextStartingTokenId;

  uint256 private mRoyaltyBasisPoints = 1000;

  modifier onlyOwnerOrDev() {
    require(msg.sender == owner() || msg.sender == mDev, "only the dev or owner can call this");
    _;
  }

  modifier onlyDev() {
    require(msg.sender == mDev,"only dev can call this");
    _;
  }

  constructor(string memory aName, string memory aSymbol, string memory aBaseURI, string memory aContractURI, address aOwner) ERC1155(aBaseURI) {
    mName = aName;
    mSymbol = aSymbol;
    mBaseURI = aBaseURI;
    mContractURI = aContractURI;
    mDev = msg.sender;
    transferOwnership(aOwner);

    mNextStartingTokenId = 1;
    mNextSubcollectionId = 1;
  }

  function mint(uint aSubcollectionId, uint aTokenId, uint aQuantity) public payable {
    require(aSubcollectionId < mNextSubcollectionId, "Not a valid subcollection");
    require(aTokenId >= mAllSubcollections[aSubcollectionId].startingTokenId, "Not a valid token id for this subcollection");
    require(aTokenId < mAllSubcollections[aSubcollectionId].startingTokenId + mAllSubcollections[aSubcollectionId].numPrimaryTokens, "Not a valid token id for this subcollection");
    require(msg.value == mAllSubcollections[aSubcollectionId].price, "Incorrect value sent");
    require(mAllSubcollections[aSubcollectionId].active, "Subcollection minting not active");
    uint256 dt = block.timestamp - mAllSubcollections[aSubcollectionId].startTime;
    require(dt <= mAllSubcollections[aSubcollectionId].totalTime, "Minting has ended.");
    require(mMintedPerWallet[aSubcollectionId][msg.sender] + aQuantity <= mAllSubcollections[aSubcollectionId].maxPerWallet, "You can't mint that many");

    mMintedPerWallet[aSubcollectionId][msg.sender] += aQuantity;

    if (dt <= mAllSubcollections[aSubcollectionId].totalTime - mAllSubcollections[aSubcollectionId].fallbackTime) {
      _mint(msg.sender, aTokenId, aQuantity, "");
    } else {
      _mint(msg.sender, mAllSubcollections[aSubcollectionId].startingTokenId + mAllSubcollections[aSubcollectionId].numPrimaryTokens, aQuantity, "");
    }
  }

  function createNewSubcollection(uint aNumPrimaryTokens, uint aPrice, uint aMaxPerWallet, uint aTotalTime, uint aFallbackTime) public onlyOwnerOrDev {
    Subcollection memory newSc = Subcollection(mNextStartingTokenId, aNumPrimaryTokens, aPrice, aMaxPerWallet, false, aTotalTime, aFallbackTime, 0); 
    mAllSubcollections[mNextSubcollectionId] = newSc;
    mNextSubcollectionId += 1;
    mNextStartingTokenId += aNumPrimaryTokens + 1; //Always 1 fallback token
  }

  function transferDev(address aNewDev) public onlyDev {
    require(aNewDev != address(0), "can't set owner to null address");
    mDev = aNewDev;
  }

  function changeURI(string memory aNewURI) public onlyOwnerOrDev {
    mBaseURI = aNewURI;
  }

  function setActive(uint aSubcollectionId, bool aActive) public onlyOwnerOrDev {
    require(aSubcollectionId < mNextSubcollectionId, "Not a valid subcollection");
    //Everytime this is set to active, the start time starts over. Even if the subcollection is active.
    //This may be useful functionality if things go wrong in the future.
    //If things need to be paused, set this to inactive and then change the times before starting
    if (aActive) mAllSubcollections[aSubcollectionId].startTime = block.timestamp;
    mAllSubcollections[aSubcollectionId].active = aActive;
  }

  function changeTimes(uint aSubcollectionId, uint aTotalTime, uint aFallbackTime) public onlyOwnerOrDev {
    require(aSubcollectionId < mNextSubcollectionId, "Not a valid subcollection");
    mAllSubcollections[aSubcollectionId].totalTime = aTotalTime;
    mAllSubcollections[aSubcollectionId].fallbackTime = aFallbackTime;
  }

  function changePrice(uint aSubcollectionId, uint aPrice) public onlyOwnerOrDev {
    require(aSubcollectionId < mNextSubcollectionId, "Not a valid subcollection");
    mAllSubcollections[aSubcollectionId].price = aPrice;
  }

  function changeRoyaltyBasisPoints(uint256 aRoyaltyBasisPoints) public onlyOwner {
    mRoyaltyBasisPoints = aRoyaltyBasisPoints;
  }

  function changeContractURI(string calldata aContractURI) public onlyOwnerOrDev {
    mContractURI = aContractURI;
  }

  function withdrawFunds() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function uri(uint256 aTokenId) override public view returns(string memory) {
    return string(
      abi.encodePacked(
        mBaseURI,
        Strings.toString(aTokenId),
        ".json"
      )
    );
  }

  function contractURI() public view returns (string memory) {
    return mContractURI;
  }

  function name() public view virtual returns (string memory) {
    return mName;
  }

  function symbol() public view virtual returns (string memory) {
    return mSymbol;
  }

  function royaltyInfo(uint256 /*aTokenId*/, uint256 aSalePrice)
    external
    view
    returns (address aReceiver, uint256 aRoyaltyAmount)
  {
    return (owner(), (aSalePrice * mRoyaltyBasisPoints) / 10000);
  }

}