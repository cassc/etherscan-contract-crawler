// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./Oil.sol";
import "./Habibi.sol";

contract Royals is ERC721AQueryable, Ownable {
    enum SaleState {
        Disabled,
        AllowlistSale,
        PublicSale
    }

    Oil public constant OIL = Oil(0x5Fe8C486B5f216B9AD83C12958d8A03eb3fD5060);
    Habibi public constant HABIBIZ = Habibi(0x98a0227E99E7AF0f1f0D51746211a245c3B859c2);

    uint256 public constant MAX_SUPPLY = 300;
    uint256 public availableSupply = 100;
    uint256 public maxClaimPerWallet = 1;
    uint256 public amountRequiredToBurn = 8;
    bytes32 public root;
    string public baseURI;
    string public notRevealedUri;

    SaleState public saleState = SaleState.Disabled;

    event SaleStateChanged(uint256 previousState, uint256 nextState, uint256 timestamp);
    event ClaimedRoyal(address indexed staker, uint256[] frozenTokenIds, uint256 indexed royalId);

    // solhint-disable-next-line no-empty-blocks
    constructor(string memory baseURI_) ERC721A("Royals", "ROYALS") {
        baseURI = baseURI_;
    }

    modifier isClaimingActive() {
        require(saleState != SaleState.Disabled, "Claiming is not active");
        _;
    }

    modifier isInAllowlist(address address_, bytes32[] calldata proof_) {
        require(saleState == SaleState.PublicSale || _verify(_leaf(address_), proof_), "Not in allowlist");
        _;
    }

    //++++++++
    // Public functions
    //++++++++

    function sacrificeAndClaim(
        uint256[] calldata habibizTokenIds_,
        uint256 royalTokenId_,
        bytes32[] calldata proof_
    ) external isClaimingActive isInAllowlist(msg.sender, proof_) {
        require(habibizTokenIds_.length >= amountRequiredToBurn, "Must burn at least required amount of habibiz");
        require(
            habibizTokenIds_.length % amountRequiredToBurn == 0,
            "Must burn multiples of required amount of habibiz"
        );
        setApprovalForAll(address(OIL), true);
        // Count number of potential mints
        uint256 numToClaim = habibizTokenIds_.length / amountRequiredToBurn;

        // O(N^2) loop, its more gas efficient to use this than a mapping with addresses, due to lower storage usage
        for (uint256 i = 0; i < habibizTokenIds_.length; i++) {
            for (uint256 j = i + 1; j < habibizTokenIds_.length; j++) {
                require(habibizTokenIds_[i] != habibizTokenIds_[j], "No duplicates allowed");
            }
        }

        // Now that we have amount a user can mint, lets ensure they can mint given maximum mints per wallet, and batch size
        require(numToClaim <= availableSupply, "available supply reached");
        // Ensure user doesn't already exceed maximum number of mints
        require(_getAux(msg.sender) < maxClaimPerWallet, "Not have enough mints available");
        // Ensure user doesn't exceed maxmium allowable number of mints
        require(uint256(_getAux(msg.sender)) + numToClaim <= maxClaimPerWallet, "Would exceed maximum allowable mints");
        // Burns staked habibis and if there was an issue burning, it reverts
        require(OIL.freeze(msg.sender, habibizTokenIds_, royalTokenId_), "Failed to claim Royal");

        _setAux(_msgSender(), uint64(numToClaim) + _getAux(msg.sender)); // Kfish - moved this to happen before mint
        emit ClaimedRoyal(msg.sender, habibizTokenIds_, royalTokenId_);
    }

    //++++++++
    // Owner functions
    //++++++++

    function mintToStakingContract(uint256 quantity_) external onlyOwner {
        require(quantity_ <= availableSupply, "Would exceed available supply");
        _safeMint(address(OIL), quantity_);
    }

    function setRoot(bytes32 root_) external onlyOwner {
        root = root_;
    }

    // Sale functions
    function setSaleState(uint256 state_) external onlyOwner {
        require(state_ < 3, "Invalid state");
        uint256 prevState = uint256(saleState);
        saleState = SaleState(state_);
        emit SaleStateChanged(prevState, state_, block.timestamp);
    }

    function setAvailableSupply(uint256 availableSupply_) external onlyOwner {
        require(availableSupply_ <= MAX_SUPPLY, "Would exceed max supply");
        availableSupply = availableSupply_;
    }

    function setmaxClaimPerWallet(uint256 maxClaimPerWallet_) public onlyOwner {
        maxClaimPerWallet = maxClaimPerWallet_;
    }

    function setBaseURI(string memory newBaseURI_) public onlyOwner {
        baseURI = newBaseURI_;
    }

    function setNotRevealedURI(string memory notRevealedURI_) public onlyOwner {
        notRevealedUri = notRevealedURI_;
    }

    function withdraw() public payable onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    function setAmountRequiredToBurn(uint256 amountRequiredToBurn_) public onlyOwner {
        amountRequiredToBurn = amountRequiredToBurn_;
    }

    //++++++++
    // Internal functions
    //++++++++
    function _leaf(address account_) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account_));
    }

    function _verify(bytes32 leaf_, bytes32[] memory proof_) internal view returns (bool) {
        return MerkleProof.verify(proof_, root, leaf_);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    //++++++++
    // Override functions
    //++++++++
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (bytes(baseURI).length == 0) {
            return notRevealedUri;
        }

        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }
}