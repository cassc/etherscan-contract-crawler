// SPDX-License-Identifier: Unlicense
// Creator: 0xYeety

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SoonBirds is ERC721, Ownable {
    using Strings for uint256;
    string public PROVENANCE;
    bool provenanceSet;

    mapping(address => uint256) private _numMinted;

    /*************************************************************************/
    /*** PAYMENT VARIABLES (Start) *******************************************/
    address[] public payees;
    mapping(address => uint256) private paymentInfo;
    uint256 totalReceived = 0;
    mapping(address => uint256) amountsWithdrawn;

    modifier onlyPayee() {
        _isPayee();
        _;
    }
    function _isPayee() internal view virtual {
        require(paymentInfo[msg.sender] > 0, "not a payee");
    }
    /*** PAYMENT VARIABLES (End) *******************************************/
    /***********************************************************************/

    bytes32 public merkleRoot2 = 0xdd7625c65d36916b4548ca9aff4cd754440291f94cc360a47455fa9ec478fe85;
    bool public mkr2Set;
    bytes32 public merkleRoot1 = 0x27ac3c141722e15297742e6ad4ce20e09c86dc00ca276ea9184e633e1ab5bf30;
    bool public mkr1Set;

    modifier soonListed(bytes32[] calldata _m1proof, bytes32[] calldata _m2proof) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_m2proof, merkleRoot2, leaf) ||
            MerkleProof.verify(_m1proof, merkleRoot1, leaf),
            "Not on SoonList!"
        );
        _;
    }

    uint256 public mintPrice = 0.02 ether;

    enum MintStatus {
        PreMint,
        AllowList,
        Public,
        Finished
    }

    MintStatus public mintStatus = MintStatus.PreMint;
    bool public paused = false;

    uint256 public maxPossibleSupply;
    uint256 public maxMintsPerWallet;

    string collectionDescription = "SoonBirds is a 5,555 piece animated tribute collection that remixes some of our favorite Creative Commons NFT projects to pay homage to the artists and how their early work has shaped the history of the NFT ecosystem. We are a community-focused project centered around collaboration and connection.";
    string collectionImg = "https://www.soonbirds.wtf/soon.gif";
    string externalLink = "https://www.soonbirds.wtf";

    constructor (
        string memory name_,
        string memory symbol_,
        uint256 maxPossibleSupply_,
        uint256 maxMintsPerWallet_,
        address[] memory payees_,
        uint256[] memory basisPoints_
    ) ERC721(name_, symbol_) {
        maxPossibleSupply = maxPossibleSupply_;
        maxMintsPerWallet = maxMintsPerWallet_;

        require(payees_.length == basisPoints_.length, "l");
        payees = payees_;
        for (uint256 i = 0; i < payees_.length; i++) {
            paymentInfo[payees_[i]] = basisPoints_[i];
        }
    }

    function min(uint256 x, uint256 y) private pure returns (uint256) {
        if (x < y) {
            return x;
        }

        return y;
    }

    function preSoon(uint256 _quantity, address _to) public onlyOwner {
        require(mintStatus == MintStatus.PreMint, "ms");

        uint256 numLeftToMint = _quantity;

        while (numLeftToMint > 0) {
            uint256 mintThisRound = 10;
            if (numLeftToMint < 10) {
                mintThisRound = numLeftToMint;
            }

            numLeftToMint -= mintThisRound;

            _safeMint(_to, mintThisRound);
        }
    }

    function changeSoonStatus(MintStatus newMintStatus) public onlyOwner {
        require(newMintStatus != MintStatus.PreMint, "nms");
        require(mintStatus != MintStatus.Finished, "ms");

        mintStatus = newMintStatus;
    }

    function flipPaused() public onlyOwner {
        paused = !paused;
    }

    function isAllowListed(address addr, bytes32[] calldata _m1proof, bytes32[] calldata _m2proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return (MerkleProof.verify(_m2proof, merkleRoot2, leaf) || MerkleProof.verify(_m1proof, merkleRoot1, leaf));
    }

    function getALMintPrice(address addr, uint256 howMany, bytes32[] calldata _m1proof, bytes32[] calldata _m2proof) public view returns (uint256) {
        require(isAllowListed(addr, _m1proof, _m2proof), "al");

        uint256 toReturn = howMany*mintPrice;

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if (MerkleProof.verify(_m2proof, merkleRoot2, leaf)) {
            if (_numMinted[addr] == 0) {
                toReturn -= min(2*mintPrice, toReturn);
            }
            else if (_numMinted[addr] == 0) {
                toReturn -= min(mintPrice, toReturn);
            }
        }
        else if (MerkleProof.verify(_m1proof, merkleRoot1, leaf)) {
            if (_numMinted[addr] == 0) {
                toReturn -= min(mintPrice, toReturn);
            }
        }

        return toReturn;
    }

    function getPublicMintPrice(uint256 howMany) public view returns (uint256) {
        return mintPrice*howMany;
    }

    function _soonMain(address _to, uint256 _quantity) private {
        require(!paused, "p");
        require(
            _numMinted[_to] + _quantity <= maxMintsPerWallet &&
            totalSupply() + _quantity <= maxPossibleSupply, "mmpw/mps");

        _safeMint(_to, _quantity);

        _numMinted[_to] += _quantity;

        if (totalSupply() == maxPossibleSupply) {
            mintStatus = MintStatus.Finished;
        }
    }

    function soonListedSoon(uint256 _quantity, bytes32[] calldata _m1proof, bytes32[] calldata _m2proof) public payable soonListed(_m1proof, _m2proof) {
        require(mintStatus == MintStatus.AllowList || mintStatus == MintStatus.Public, "ms");
        require(msg.value >= getALMintPrice(msg.sender, _quantity, _m1proof, _m2proof));

        totalReceived += msg.value;
        _soonMain(msg.sender, _quantity);
    }

    function soon(uint256 _quantity) public payable {
        require(mintStatus == MintStatus.Public, "ms");
        require(msg.value >= _quantity*mintPrice);

        totalReceived += msg.value;
        _soonMain(msg.sender, _quantity);
    }

    //////////

    function setPreRevealURI(string memory preRevealURI_) public onlyOwner {
        _setPreRevealURI(preRevealURI_);
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        require(!provenanceSet);
        PROVENANCE = provenanceHash;
        provenanceSet = true;
    }

    //////////

    function setCollectionDescription(string memory _collectionDescription) public onlyOwner {
        collectionDescription = _collectionDescription;
    }

    function setCollectionImg(string memory _collectionImg) public onlyOwner {
        collectionImg = _collectionImg;
    }

    function setExternalLink(string memory _externalLink) public onlyOwner {
        externalLink = _externalLink;
    }

    function contractURI() public view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;utf8,{\"name\":\"SoonBirds\",",
                "\"description\":\"", collectionDescription, "\",",
                "\"image\":\"", collectionImg, "\",",
                "\"external_link\":\"", externalLink, "\",",
                "\"seller_fee_basis_points\":690,\"fee_recipient\":\"",
                uint256(uint160(address(this))).toHexString(), "\"}"
            )
        );
    }

    /*********************************************************************/
    /*** PAYMENT LOGIC (Start) *******************************************/
    receive() external payable {
        totalReceived += msg.value;
    }

    function withdraw() public onlyPayee {
        uint256 totalForPayee = (totalReceived/10000)*paymentInfo[msg.sender];
        uint256 toWithdraw = totalForPayee - amountsWithdrawn[msg.sender];
        amountsWithdrawn[msg.sender] = totalForPayee;
        (bool success, ) = payable(msg.sender).call{value: toWithdraw}("");
        require(success, "Payment failed!");
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 toWithdraw = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: toWithdraw}("");
        require(success, "Payment failed!");
    }

    function withdrawTokens(address tokenAddress) external onlyPayee {
        for (uint256 i = 0; i < payees.length; i++) {
            IERC20(tokenAddress).transfer(
                payees[i],
                (IERC20(tokenAddress).balanceOf(address(this))/10000)*paymentInfo[payees[i]]
            );
        }
    }

    function emergencyWithdrawTokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }
    /*** PAYMENT LOGIC (End) *******************************************/
    /*******************************************************************/
}

////////////////////////////////////////