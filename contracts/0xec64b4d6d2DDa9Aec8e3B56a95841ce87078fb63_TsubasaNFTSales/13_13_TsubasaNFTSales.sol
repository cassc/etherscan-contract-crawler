pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../abstract/CustomIdMint.sol";
import "forge-std/console.sol";

/**
 * SPDX-License-Identifier: MIT
 * @title TsubasaNFTSales
 * @author double jump.tokyo
 * @notice The contract that handles Tsubasa NFT sale
 */
contract TsubasaNFTSales is Ownable, CustomIdMint {
    error PrivateMintAlreadyExecuted(address _buyer);
    error SaleNotStarted();
    error VerificationFailed();
    error InvalidPayment();

    using ECDSA for bytes32;

    uint256 public privateSalePrice = 0.06 ether;
    uint256 public publicSalePrice = 0.08 ether;

    uint256 public totalSold = 0;

    uint256 public privateSaleStartAt;
    uint256 public privateSaleEndAt;

    uint256 public publicSaleStartAt;
    uint256 public publicSaleEndAt;

    /// @dev The EOA generating signature to check if a user allowed to call privateMint
    address private validator;

    /// @dev Used to prevent Signature Replay Attack
    mapping(address => bool) public privateMintExecuted;

    modifier onlyFirstPrivateMint() {
        if (privateMintExecuted[msg.sender])
            revert PrivateMintAlreadyExecuted(msg.sender);
        _;
    }

    modifier privateSaleStarted() {
        if (!isPrivateSaleActive()) revert SaleNotStarted();
        _;
    }

    modifier publicSaleStarted() {
        if (!isPublicSaleActive()) revert SaleNotStarted();
        _;
    }

    modifier verified(uint256 _mintAmount, bytes calldata _signature) {
        if (!_verifySignature(_mintAmount, _signature))
            revert VerificationFailed();
        _;
    }

    /**
     * @notice initialize sales contract.
     * @param _owner the owner of this contract.
     * @param _validator the validator of the private mint.
     * @param _nft the nft address to be sold.
     */
    constructor(
        address _owner,
        address _validator,
        address _nft,
        uint8 _usageId
    ) CustomIdMint(_nft, _usageId) {
        validator = _validator;
        transferOwnership(_owner);
    }

    /**
     * public functions
     */

    /// @inheritdoc CustomIdMint
    function startNewSeries() public override onlyOwner {
        CustomIdMint.startNewSeries();
    }

    /**
     * @notice check if private sale is being held
     */
    function isPrivateSaleActive() public view returns (bool) {
        return
            privateSaleStartAt != 0 &&
            privateSaleEndAt != 0 &&
            block.timestamp >= privateSaleStartAt &&
            block.timestamp <= privateSaleEndAt;
    }

    /**
     * @notice check if public sale is being held
     */
    function isPublicSaleActive() public view returns (bool) {
        return
            publicSaleStartAt != 0 &&
            publicSaleEndAt != 0 &&
            block.timestamp >= publicSaleStartAt &&
            block.timestamp <= publicSaleEndAt;
    }

    /**
     * external functions
     */

    /**
     * @notice execute private mint. this can be called by the address
     *         a validator allowed with signature.
     */
    function privateMint(
        uint256 _mintAmount,
        bytes calldata _signature
    )
        external
        payable
        onlyFirstPrivateMint
        privateSaleStarted
        verified(_mintAmount, _signature)
    {
        _mint(_mintAmount, privateSalePrice);

        privateMintExecuted[msg.sender] = true;
    }

    /**
     * @notice execute public mint
     */
    function publicMint(
        uint256 _mintAmount
    ) external payable publicSaleStarted {
        _mint(_mintAmount, publicSalePrice);
    }

    /**
     * @notice withdraw all balance of the contract. this can only be called by the owner
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * @notice set private sale time
     * @param _startAt sale start time
     * @param _endAt sale end time
     */
    function setPrivateSaleTime(
        uint256 _startAt,
        uint256 _endAt
    ) external onlyOwner {
        privateSaleStartAt = _startAt;
        privateSaleEndAt = _endAt;
    }

    /**
     * @notice set public sale time
     * @param _startAt sale start time
     * @param _endAt sale end time
     */
    function setPublicSaleTime(
        uint256 _startAt,
        uint256 _endAt
    ) external onlyOwner {
        publicSaleStartAt = _startAt;
        publicSaleEndAt = _endAt;
    }

    /**
     * @notice set nft price on the private sale
     * @param _price nft price in Wei. e.g. To set price for 0.5ETH, You give 0.5e18(=5*10^17) as a parameter
     */
    function setPrivateSalePrice(uint256 _price) external onlyOwner {
        privateSalePrice = _price;
    }

    /**
     * @notice set nft price on the public sale
     * @param _price nft price in Wei. e.g. To set price for 0.5ETH, You give 0.5e18(=5*10^17) as a parameter
     */
    function setPublicSalePrice(uint256 _price) external onlyOwner {
        publicSalePrice = _price;
    }

    /**
     * @notice set validator for the private sale
     * @param _validator validator address. this should be an EOA to create signature
     */
    function setValidator(address _validator) external onlyOwner {
        validator = _validator;
    }

    /**
     * private functions
     */

    /**
     * @dev check if mint can be called
     * @param cost expected user's cost
     */
    function _checkUserPayment(uint256 cost) private view {
        if (msg.value != cost) revert InvalidPayment();
    }

    /**
     * @dev verifying if the address is allowed to mint
     * @param _mintAmount the amount a user will mint
     * @param _signature the signature generated by a validator
     */
    function _verifySignature(
        uint256 _mintAmount,
        bytes memory _signature
    ) private view returns (bool) {
        return
            validator ==
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    keccak256(
                        abi.encode(address(this), msg.sender, _mintAmount)
                    )
                ),
                _signature
            );
    }

    /**
     * @dev mint NFT with specified amount. actual mint logic is
     *      written in CustomIdMint.sol
     * @param _mintAmount the amount user will mint
     * @param _price the price of NFT
     */
    function _mint(uint256 _mintAmount, uint256 _price) private {
        uint256 cost = _price * _mintAmount;
        _checkUserPayment(cost);

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _mint();
        }

        totalSold += _mintAmount;
    }
}