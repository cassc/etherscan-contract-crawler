// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libraries/NftMintingStation.sol";

/**
 * @title Samurai Saga Land Minter
 * @notice SamuraiSagaLand ERC721 NFT Minter contract
 * https://www.samuraisaga.com
 */
contract SamuraiSagaLandMinter is NftMintingStation, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct MintConfiguration {
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 maxMint;
        uint256 price;
    }

    bytes32 public constant SIGN_MINT_TYPEHASH = keccak256("Mint(address account,uint256 quantity,uint256 value)");

    address public immutable creator = 0x3FADe707B6258873cDBC67956439423802c6DEa2;

    MintConfiguration public mintConfiguration;
    mapping(uint256 => uint256) private _tokenIdsCache;
    mapping(address => uint256) public userMints;

    event Withdraw(uint256 amount);

    modifier whenMintOpened() {
        require(mintConfiguration.startTimestamp > 0, "Mint not configured");
        require(mintConfiguration.startTimestamp <= block.timestamp, "Mint not opened");
        require(
            mintConfiguration.endTimestamp == 0 || mintConfiguration.endTimestamp >= block.timestamp,
            "Mint closed"
        );
        _;
    }

    constructor(INftCollection collection) NftMintingStation(collection, "SamuraiSagaLand", "1.0") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _syncSupply();
    }

    /**
     * @dev mint a `quantity` NFT (quantity max is limited per wallet)
     * signature: backend signature for the transaction
     */
    function mint(
        uint256 quantity,
        bytes memory signature
    ) external payable nonReentrant whenValidQuantity(quantity) whenMintOpened {
        address to = _msgSender();
        require(userMints[to] + quantity <= mintConfiguration.maxMint, "Above quantity allowed");

        uint256 value = mintConfiguration.price * quantity;
        require(isAuthorized(_hashMintPayload(to, quantity, value), signature), "Not signed by authorizer");
        require(msg.value >= value, "Payment failed");

        userMints[to] += quantity;
        _mint(to, quantity);
    }

    /**
     * @dev airdrop NFTs
     */
    function mintAirdrop(address[] calldata destinations, uint256[] calldata quantities) external onlyOwnerOrOperator {
        require(availableSupply > 0, "No more supply");
        require(destinations.length == quantities.length, "Invalid data");

        for (uint256 i = 0; i < destinations.length; i++) {
            require(availableSupply >= quantities[i], "Not enough supply");
            _mint(destinations[i], quantities[i]);
        }
    }

    function _withdraw(uint256 amount) private {
        require(amount <= address(this).balance, "amount > balance");
        require(amount > 0, "Empty amount");

        payable(creator).transfer(amount);
        emit Withdraw(amount);
    }

    /**
     * @dev withdraw selected amount
     */
    function withdraw(uint256 amount) external onlyOwnerOrOperator {
        _withdraw(amount);
    }

    /**
     * @dev withdraw full balance
     */
    function withdrawAll() external onlyOwnerOrOperator {
        _withdraw(address(this).balance);
    }

    /**
     * @dev configure the round
     */
    function configureMint(MintConfiguration calldata configuration) external onlyOwnerOrOperator {
        require(
            configuration.endTimestamp == 0 || configuration.startTimestamp < configuration.endTimestamp,
            "Invalid timestamps"
        );
        require(configuration.maxMint > 0, "Invalid max mint");
        mintConfiguration = configuration;
    }

    function _getNextRandomNumber() private returns (uint256 index) {
        require(availableSupply > 0, "Invalid _remaining");

        // pseudo random
        uint256 i = (maxSupply + uint256(keccak256(abi.encode(msg.sender, blockhash(block.number))))) % availableSupply;

        // if there's a cache at _tokenIdsCache[i] then use it
        // otherwise use i itself
        index = _tokenIdsCache[i] == 0 ? i : _tokenIdsCache[i];

        // grab a number from the tail
        _tokenIdsCache[i] = _tokenIdsCache[availableSupply - 1] == 0
            ? availableSupply - 1
            : _tokenIdsCache[availableSupply - 1];
    }

    function getNextTokenId() internal override returns (uint256 index) {
        return _getNextRandomNumber() + 1;
    }

    function _hashMintPayload(address _account, uint256 quantity, uint256 _value) internal pure returns (bytes32) {
        return keccak256(abi.encode(SIGN_MINT_TYPEHASH, _account, quantity, _value));
    }
}