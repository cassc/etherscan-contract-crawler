// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./CappedCrowdsale.sol";
import "./TimedCrowdsale.sol";
import "./Crowdsale.sol";
import "./CrowdsaleAccessControl.sol";
import "../Inventory/CCOFInventory.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CCOFAllowedSale3 is
    Crowdsale,
    TimedCrowdsale,
    CappedCrowdsale,
    CrowdsaleAccessControl
{
    /**
     *@dev number of purchases by a AL user within AL limit
     */
    mapping(address => uint256) public purchase;

    /**
     *@dev purchase limit per user for AL
     */

    uint256 public purchaseLimit;

    /**
     * @dev
     * @param txTokenLimit token limit per transaction
     */
    uint256 public immutable txTokenLimit = 2;

    /**
     *@dev allowlistMerkleRoot Root of AL Merkle Tree
     */

    bytes32 allowlistMerkleRoot;

    CCOFInventory public inventory;

    /**
     * @dev owner can set new opening time through the setter function
     * @param _openingTime new opening time of the crowdsale
     */

    function setOpeningTime(uint256 _openingTime) public onlyOwner {
        openingTime = _openingTime;
    }

    /**
     * @dev owner can set new closing time through the setter function
     * @param _closingTime new closing time of the crowdsale
     */

    function setClosingTime(uint256 _closingTime) public onlyOwner {
        closingTime = _closingTime;
    }

    /**
     * @dev owner can set new price through the setter function
     * @param _price new price of the token
     */

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    /**
     * @dev owner can set new merkle root through the setter function
     * @param _merkleRoot new value for merkle root.
     */

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        allowlistMerkleRoot = _merkleRoot;
    }

    /**
     * Constructor.
     * @param _inventory addresss of the inventory contract
     * @param _cap total supply of tokens
     * @param _openingTime start time of the crowdsale
     * @param _closingTime end time of the crowdsale
     * @param _purchaseLimit token limit of a user
     * @param _price price of the token.
     * @param _treasury wallet where all collected funds are stored
     * @param _merkleRoot root of the merkle tree
     */

    constructor(
        address _inventory,
        uint256 _cap,
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _purchaseLimit,
        uint256 _price,
        address payable _treasury,
        bytes32 _merkleRoot
    )
        CrowdsaleAccessControl()
        Crowdsale(_price, _treasury)
        CappedCrowdsale(_cap)
        TimedCrowdsale(_openingTime, _closingTime)
    {
        purchaseLimit = _purchaseLimit;
        allowlistMerkleRoot = _merkleRoot;
        inventory = CCOFInventory(_inventory);
    }

    /**
     * @dev Executed when a user is buying tokens
     * @param _proof proof of given address
     * The validation is performed only on the first mint of the user.
     * Users can buy tokens only if the proof is valid.
     */

    function buyTokensPresale(bytes32[] calldata _proof) public payable {
        require(
            isValidMerkleProof(msg.sender, _proof),
            "ERROR:User is not in the allow list"
        );
        buyTokens();
    }

    /**
     * @dev Validation is performed when a user is buying tokens for the first time.
     *@param _beneficiary address of the user.
     * @param merkleProof proof of the given address.
     * The validation is performed to check if the user is in the allowlist or not.
     * Only validated users can buy tokens.
     */

    function isValidMerkleProof(
        address _beneficiary,
        bytes32[] calldata merkleProof
    ) public view returns (bool) {
        return
            MerkleProof.verify(
                merkleProof,
                allowlistMerkleRoot,
                keccak256(abi.encodePacked(_beneficiary))
            );
    }

    function _getTokenAmount(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _price
    ) internal override(Crowdsale) returns (uint256) {
        uint256 tokenAmount = super._getTokenAmount(
            _beneficiary,
            _weiAmount,
            _price
        );

        uint256 remainingPurchase = purchaseLimit - purchase[_beneficiary];

        if ((tokenSold + tokenAmount) > cap) {
            tokenAmount = cap - tokenSold;
        }
        if (tokenAmount > txTokenLimit) {
            tokenAmount = txTokenLimit;
        }
        if (tokenAmount > remainingPurchase) {
            return remainingPurchase;
        }

        return tokenAmount;
    }

    function _preValidatePurchase(address _beneficiary, uint256 _tokenAmount)
        internal
        override(CappedCrowdsale, TimedCrowdsale, Crowdsale)
        whenNotPaused
    {
        require(
            _tokenAmount <= txTokenLimit,
            "ERROR:Max 2 mints in one transaction"
        );

        require(
            purchase[_beneficiary] < purchaseLimit,
            "ERROR:Exceeded purchase limit"
        );

        super._preValidatePurchase(_beneficiary, _tokenAmount);
    }

    function _updatePurchasingState(
        address _beneficiary,
        uint256 _tokenAmount,
        uint256 _weiAmount
    ) internal override {
        purchase[_beneficiary] = purchase[_beneficiary] + _tokenAmount;

        require(
            purchaseLimit >= purchase[_beneficiary],
            "ERROR: Max 2 mints per user"
        );

        super._updatePurchasingState(_beneficiary, _tokenAmount, _weiAmount);
    }

    function _deliverToken(address _beneficiary, uint256 tokenAmount)
        internal
        override
    {
        inventory.mint(_beneficiary, tokenAmount);
    }
}