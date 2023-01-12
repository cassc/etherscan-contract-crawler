// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./openzeppelin/token/ERC721/ERC721.sol";
import "./opensea-filter/DefaultOperatorFilterer.sol";
import "./openzeppelin/access/Ownable.sol";
import "./openzeppelin/utils/Strings.sol";
import "./openzeppelin/security/ReentrancyGuard.sol";

import "./openzeppelin/utils/cryptography/MerkleProof.sol";


contract Eggditions is ERC721, DefaultOperatorFilterer, Ownable, ReentrancyGuard {
    address public mDev;

    mapping(address => uint256) public mMintedPerWallet;

    uint256 constant public cPublicPrice = 0.2 ether;
    uint256 constant public cPublicQuantityAllowed = 1;
    string public mContractURI;
    string public mBaseURI;

    uint256 public mNextTokenId = 1;
    uint256 constant public cMaxToken = 240;
    uint256 public mTokenOffset = 0;

    uint256 public mRoyaltyBasisPoints = 1000;

    bytes32 private mMerkleRoot;
    bytes32 public mProvHash;
    bool public mAllowlistActive = false;
    bool public mWaitlistActive = false;
    bool public mPublicActive = false;

    modifier onlyOwnerOrDev() {
        require(msg.sender == owner() || msg.sender == mDev, "only the dev or owner can call this");
        _;
    }

    modifier onlyDev() {
        require(msg.sender == mDev,"only dev can call this");
        _;
    }

    constructor(string memory aName, string memory aSymbol, address aOwner, string memory aBaseURI, string memory aContractURI) ERC721(aName, aSymbol) {
        mBaseURI = aBaseURI;
        mContractURI = aContractURI;
        mDev = msg.sender;
        transferOwnership(aOwner);
    } 

    function mint(bytes32[] memory aMerkleProof, string memory aMintType, uint256 aMintTypeNum, uint256 aQuantity, uint256 aQuantityAllowed, uint256 aPriceWei) public nonReentrant payable {
        require(msg.sender == tx.origin, "not callable by contracts");
        require(mNextTokenId <= cMaxToken, "sold out");
        require(aMintTypeNum <= 3 && aMintTypeNum > 0, "invalid mint phase");
        require((mAllowlistActive && aMintTypeNum == 1) || (mWaitlistActive && aMintTypeNum == 2) || mPublicActive, "phase not open");
        require(aQuantity < 10, "sanity check on quantity failed");
        require(aQuantityAllowed < 10, "sanity check on quantity allowed failed");
        require(aPriceWei < 1 ether, "sanity check on price failed");

        uint256 price           = aMintTypeNum == 3 ? cPublicPrice : aPriceWei;
        uint256 quantityAllowed = aMintTypeNum == 3 ? cPublicQuantityAllowed : aQuantityAllowed;
        bool canMint            = aMintTypeNum == 3 ? true : MerkleProof.verify(aMerkleProof, mMerkleRoot, keccak256(abi.encodePacked(msg.sender, aMintType, aQuantityAllowed, aPriceWei)));
        require(canMint, "unable to mint due to merkle fail");
        
        //if you've made it this far, this is a valid mint request
        require(msg.value == aQuantity*price, "wrong eth sent");
        require(mMintedPerWallet[msg.sender] + aQuantity <= quantityAllowed, "Can't mint any more");
        require(mNextTokenId + aQuantity - 1 <= cMaxToken, "not enough tokens left");

        for (uint256 i = 0; i < aQuantity; i = i + 1){
            unchecked {
                mMintedPerWallet[msg.sender] += 1;
            }
            _mint(msg.sender, mNextTokenId);
            unchecked {
                mNextTokenId += 1;
            }
        }
    }  

    function setPhaseActive(uint256 aPhase, bool aActive) public onlyOwnerOrDev {
        require(aPhase <= 3, "not a valid phase");
        if (aPhase == 1) mAllowlistActive = aActive;
        else if (aPhase == 2) mWaitlistActive = aActive;
        else if (aPhase == 3) mPublicActive = aActive;
    }

    function setMerkleRoot(bytes32 aRoot) public onlyOwnerOrDev {
        mMerkleRoot = aRoot;
    }

    function setTokenOffset(uint256 aWordConvertedToNumbers) public onlyOwnerOrDev {
        require(mTokenOffset == 0, "can only call this once");
        uint256 randomNum = uint256(
            keccak256(
                abi.encode(
                    msg.sender,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    address(this),
                    aWordConvertedToNumbers
                )
            )
        );

        mTokenOffset = randomNum;

        //Sanity checks since we are dealing with very large numbers
        if ((2**256 - 1) - mTokenOffset < 250) { //mTokenOffset was so high that there could be overflow issues
            mTokenOffset -= 250;
        }
    }

    function getOffsetTokenId(uint256 tokenId) public view returns (uint256) {
        //the minus and plus 1 ensures this is between 1 and maxSupply because mod will return 0
        return (((tokenId - 1 + mTokenOffset) % cMaxToken) + 1);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "cannot query non-existent token");
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(getOffsetTokenId(tokenId)), '.json'));
    }

    function baseTokenURI() public view returns (string memory) {
        return mBaseURI;
    }

    function changeURI(string memory aNewURI) public onlyOwnerOrDev {
        mBaseURI = aNewURI;
    }

    function changeRoyaltyBasisPoints(uint256 aRoyaltyBasisPoints) public onlyOwner {
        mRoyaltyBasisPoints = aRoyaltyBasisPoints;
    }

    function changeContractURI(string calldata aContractURI) public onlyOwnerOrDev {
        mContractURI = aContractURI;
    }

    function setProvHash(bytes32 aHash) public onlyOwnerOrDev {
        mProvHash = aHash;
    }

    function withdrawFunds() public onlyOwnerOrDev {
        uint256 split1 = 4000;
        uint256 split2 = 2000;
        uint256 startingBal = address(this).balance;
        payable(mDev).transfer((startingBal * split1) / 10000);
        payable(0x4018360d59D37B689c70E962C15d1cE37a65a488).transfer((startingBal * split2) / 10000);

        //remove remaining
        payable(owner()).transfer(address(this).balance);
    }

    function contractURI() public view returns (string memory) {
        return mContractURI;
    }

    function royaltyInfo(uint256 /*aTokenId*/, uint256 aSalePrice)
        external
        view
        returns (address aReceiver, uint256 aRoyaltyAmount)
    {
        return (owner(), (aSalePrice * mRoyaltyBasisPoints) / 10000);
    }

    //Functions for OperatorFilter
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}