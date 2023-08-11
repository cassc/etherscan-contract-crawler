//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Interfaces/ICrowdsale.sol";
import "./Interfaces/ILisaSettings.sol";
import "./Interfaces/IArtTokenVault.sol";
import "./Interfaces/IArtBuyout.sol";
import "./Interfaces/IArtToken.sol";

contract ArtTokenVault is AccessControlUpgradeable, IArtTokenVault {
    event ERC20CrowdsaleCreated(
        address crowdsaleAddress,
        address tokenAddress,
        address vaultAddress
    );
    event ArtBuyoutCreated(address buyoutAddressAddress, address buyer);

    using SafeERC20 for IERC20;
    using Address for address;

    bytes32 public constant SELLER_ROLE = keccak256("SELLER_ROLE");

    /// @notice the ERC721 token address of the vault's token
    IArtERC721 private nftContract;

    IArtToken private tokenAT;
    string private tokenNameAT;
    string private tokenSymbolAT;

    ILisaSettings public immutable settings;

    /// @notice Currently active crowdsale contract. Can be address(0) if no crowdsale was deployed.
    ICrowdsale public crowdsale;

    /// @notice Currently active buyout contract. Can be address(0) if no buyout was deployed.
    IArtBuyout public buyout;

    /// @notice The address of the logic contract for buyout which is set at the crowdsale deployment.
    address public buyoutLogic;

    /// @notice the address of the seller who deployed this contract or who bought out the artwork
    /// @dev the seller is the only one who can mint and burn tokens
    address public seller;

    constructor(ILisaSettings _settings) {
        settings = _settings;
        _disableInitializers();
    }

    function initialize(
        address sellerAddress,
        IArtERC721 nftToken,
        string memory ftName,
        string memory ftSymbol
    ) external initializer {
        require(
            address(nftToken) != address(0),
            "nftToken address should not be 0"
        );
        require(
            address(sellerAddress) != address(0),
            "seller address should not be 0"
        );
        tokenNameAT = ftName;
        tokenSymbolAT = ftSymbol;
        nftContract = nftToken;
        seller = sellerAddress;
        _grantRole(SELLER_ROLE, sellerAddress);
    }

    /**
     * @return the token stored in the vault.
     */
    function token() external view returns (address) {
        return address(tokenAT);
    }

    /// @notice Mints a new NFT. Can only be called by a seller, and only before or after a crowdsale
    /// @param tokenURI Token metadata
    /// @dev calls nftContract to mint a token
    /// @return New token id
    function mintNFT(
        string memory tokenURI
    ) public onlyRole(SELLER_ROLE) returns (uint256) {
        require(
            crowdsaleStatus() != CrowdsaleStatus.IN_PROGRESS,
            "Crowdsale in progress"
        );
        require(
            crowdsaleStatus() != CrowdsaleStatus.SUCCESSFUL,
            "Crowdsale has successfully completed"
        );
        uint256 newTokenId = nftContract.mintItem(address(this), tokenURI);
        return newTokenId;
    }

    /// @notice Mints a new NFT. Can only be called by a seller, and only before or after a crowdsale
    /// @param tokenId Token id to burn. Should exist in the ERC721 contract.
    /// @dev calls nftContract to burn a token
    function burnNFT(uint256 tokenId) external onlyRole(SELLER_ROLE) {
        require(
            crowdsaleStatus() != CrowdsaleStatus.IN_PROGRESS,
            "Crowdsale in progress"
        );
        require(
            crowdsaleStatus() != CrowdsaleStatus.SUCCESSFUL,
            "Crowdsale has successfully completed"
        );
        nftContract.burnItem(tokenId);
    }

    /// @notice Returns the crowdsale status. If the crowdsale has not started, returns NOT_STARTED.
    /// @dev if crowdsale had been initialized, calls underlying crowdsale.status().
    /// @return CrowdsaleStatus enum value.
    function crowdsaleStatus() public view returns (CrowdsaleStatus) {
        if (address(crowdsale) == address(0)) {
            return CrowdsaleStatus.NOT_PLANNED;
        }
        return crowdsale.status();
    }

    function _deployArtToken() private {
        IArtToken newAtToken = IArtToken(
            Clones.clone(settings.getLogic(keccak256("ArtTokenERC20V1")))
        );
        newAtToken.initialize(tokenNameAT, tokenSymbolAT);
        tokenAT = newAtToken;
    }

    /// @notice Transfers the ownership of the vault to a new owner.
    function _transferOwnership(address newOwner) internal {
        _revokeRole(SELLER_ROLE, seller);
        _grantRole(SELLER_ROLE, newOwner);
        seller = newOwner;
    }

    // -------------------  EXTERNAL, MUTATING  -------------------

    /**
     * @notice  Deploys new ERC20 crowdsale contract. Can only be called by a seller. Can only be called if no crowdsale is currently in progress
     * or if the previous crowdsale was unsuccessful. Always deploys a new ArtTokenERC20 contract and mints the full supply plus protocol fee to the new crowdsale address.
     * @dev     .
     * @param   rate  The amount of AT tokens units received for each base token unit taking decimals into account. AT = BT * rate.
     * @param   baseToken  The address of ERC20 token that will be used to participate in the crowdsale.
     * @param   startDate  UNIX timestamp of the start date of the crowdsale in seconds.
     * @param   endDate  UNIX timestamp of the end date of the crowdsale in seconds.
     * @param   supply  Total supply of AT tokens minted for the crowdsale.
     * @param   sellerRetainedAmount  The amount of AT tokens units that will be retained by the seller.
     * @param   minParticipationBT  .
     * @param   maxParticipationBT  .
     * @return  Address of the new crowdsale  .
     */
    function deploySimpleCrowdsale(
        uint256 rate,
        IERC20 baseToken,
        uint256 startDate,
        uint256 endDate,
        uint256 supply,
        uint256 sellerRetainedAmount,
        uint256 minParticipationBT,
        uint256 maxParticipationBT
    ) public onlyRole(SELLER_ROLE) returns (address) {
        require(
            address(baseToken) != address(0),
            "baseToken address should not be 0"
        );
        require(
            supply > sellerRetainedAmount,
            "Supply should be > sellerRetainedAmount"
        );
        require(
            crowdsaleStatus() == CrowdsaleStatus.NOT_PLANNED ||
                crowdsaleStatus() == CrowdsaleStatus.UNSUCCESSFUL,
            "Crowdsale has already been initialized"
        );
        _deployArtToken();
        CrowdsaleSimpleInitParams memory params = CrowdsaleSimpleInitParams(
            rate,
            seller,
            tokenAT,
            baseToken,
            startDate,
            endDate,
            supply,
            sellerRetainedAmount,
            minParticipationBT,
            maxParticipationBT,
            settings
        );

        ICrowdsale newCrowdsale = ICrowdsale(
            Clones.clone(settings.getLogic(keccak256("LisaCrowdsaleSimple")))
        );
        address(newCrowdsale).functionCall(
            abi.encodeWithSignature(
                "initialize((uint256,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,address))",
                params
            )
        );
        newCrowdsale.addWhitelister(settings.protocolAdmin());
        emit ERC20CrowdsaleCreated(
            address(newCrowdsale),
            address(tokenAT),
            address(this)
        );
        tokenAT.mint(address(newCrowdsale), supply);
        crowdsale = newCrowdsale;
        buyoutLogic = settings.getLogic(keccak256("BuyoutV1"));
        return address(crowdsale);
    }

    /**
     * @notice  Deploys new ERC20 crowdsale contract. Can only be called by a seller. Can only be called if no crowdsale is currently in progress
     * or if the previous crowdsale was unsuccessful. Always deploys a new ArtTokenERC20 contract and mints the full supply plus protocol fee to the new crowdsale address.
     * @param   rate  The amount of AT tokens units received for each base token unit taking decimals into account. AT = BT * rate.
     * @param   baseToken  The address of ERC20 token that will be used to participate in the crowdsale.
     * @param   presaleStartDate  UNIX timestamp of the presale start date of the crowdsale in seconds.
     * @param   startDate  UNIX timestamp of the start date of the crowdsale in seconds.
     * @param   endDate  UNIX timestamp of the end date of the crowdsale in seconds.
     * @param   supply  Total supply of AT tokens minted for the crowdsale.
     * @param   sellerRetainedAmount  The amount of AT tokens units that will be retained by the seller.
     * @param   minParticipationBT Minimum buyToken amountBT per transaction for each participant.
     * @param   maxParticipationBT Maximum buyToken amountBT in total for each participant.
     * @return  Address of the new crowdsale  .
     */
    function deployProportionalCrowdsale(
        uint256 rate,
        IERC20 baseToken,
        uint256 presaleStartDate,
        uint256 startDate,
        uint256 endDate,
        uint256 supply,
        uint256 sellerRetainedAmount,
        uint256 minParticipationBT,
        uint256 maxParticipationBT
    ) public onlyRole(SELLER_ROLE) returns (address) {
        require(
            address(baseToken) != address(0),
            "baseToken address should not be 0"
        );
        require(
            supply > sellerRetainedAmount,
            "Supply should be > sellerRetainedAmount"
        );
        require(
            crowdsaleStatus() == CrowdsaleStatus.NOT_PLANNED ||
                crowdsaleStatus() == CrowdsaleStatus.UNSUCCESSFUL,
            "Crowdsale has already been initialized"
        );
        _deployArtToken();
        CrowdsaleProportionalInitParams
            memory params = CrowdsaleProportionalInitParams(
                rate,
                seller,
                tokenAT,
                baseToken,
                presaleStartDate,
                startDate,
                endDate,
                supply,
                sellerRetainedAmount,
                minParticipationBT,
                maxParticipationBT,
                settings
            );
        ICrowdsale newCrowdsale = ICrowdsale(
            Clones.clone(
                settings.getLogic(keccak256("LisaCrowdsaleProportional"))
            )
        );
        address(newCrowdsale).functionCall(
            abi.encodeWithSignature(
                "initialize((uint256,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,address))",
                params
            )
        );
        newCrowdsale.addWhitelister(settings.protocolAdmin());
        emit ERC20CrowdsaleCreated(
            address(newCrowdsale),
            address(tokenAT),
            address(this)
        );
        tokenAT.mint(address(newCrowdsale), supply);
        crowdsale = newCrowdsale;
        buyoutLogic = settings.getLogic(keccak256("BuyoutV1"));
        return address(crowdsale);
    }

    // @notice Deploys a new buyout contract. BaseToken is the same as during the last crowdsale. Can only be deployed
    // with a higher amount of base tokens than the previous sale.
    // @param amountBT The amount of base tokens to be paid for the artwork.
    function deployBuyout(uint256 amountBT) public returns (address) {
        require(
            address(crowdsale) != address(0) &&
                crowdsale.status() == CrowdsaleStatus.SUCCESSFUL,
            "Crowdsale should have been successful before starting a buyout"
        );
        require(
            amountBT > crowdsale.totalPriceBT(),
            "ArtTokenVault: buyout amount should be greater than the previous sale"
        );
        require(
            address(buyout) == address(0) ||
                buyout.status() == BuyoutStatus.UNSUCCESSFUL,
            "ArtTokenVault: Buyout is already in progress"
        );
        uint256 successVoteThreshold = tokenAT.totalSupply() / 2;
        IArtBuyout newBuyout = IArtBuyout(Clones.clone(buyoutLogic));
        newBuyout.initialize(
            _msgSender(),
            tokenAT,
            block.timestamp + settings.buyoutDurationSeconds(),
            successVoteThreshold,
            crowdsale.tokenBT(),
            amountBT
        );
        buyout = newBuyout;
        emit ArtBuyoutCreated(address(newBuyout), _msgSender());
        crowdsale.tokenBT().safeTransferFrom(
            _msgSender(),
            address(newBuyout),
            amountBT
        );
        return address(newBuyout);
    }

    /// @notice Transfers ownership of the vault to the buyer of the buyout.
    /// Can only be called by the new buyer after the successful buyout.
    /// Removes AT token address and sets crowdsale
    function claimNewOwnership() external {
        require(
            buyout != IArtBuyout(address(0)) &&
                buyout.status() == BuyoutStatus.SUCCESSFUL,
            "Buyout not successful"
        );
        require(
            _msgSender() == buyout.buyer(),
            "Only buyout buyer can claim ownership"
        );

        _transferOwnership(buyout.buyer());
        tokenAT = IArtToken(address(0));
        tokenNameAT = "";
        crowdsale = ICrowdsale(address(0));
        buyout = IArtBuyout(address(0));
        buyoutLogic = address(0);
    }
}