/* Copyright (C) 2021 NexusMutual.io
  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.7.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./interfaces/IGateway.sol";
import "./interfaces/IPool.sol";
import "./interfaces/INXMaster.sol";

contract NexusV1Distributor is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    string public constant DEFAULT_BASE_URI =
        "https://app.brightunion.io/img/nfts/nexus/cover.png";

    event ClaimPayoutRedeemed(
        uint256 indexed coverId,
        uint256 indexed claimId,
        address indexed receiver,
        uint256 amountPaid,
        address coverAsset
    );

    event ClaimSubmitted(
        uint256 indexed coverId,
        uint256 indexed claimId,
        address indexed submitter
    );

    event CoverBought(
        uint256 indexed coverId,
        address indexed buyer,
        address indexed contractAddress,
        uint256 feePercentage,
        uint256 coverPrice
    );

    event BuyCoverEvent(
        address _productAddress,
        uint256 _productId,
        uint256 _period,
        address _asset,
        uint256 _amount,
        uint256 _price
    );

    /*
     feePercentage applied to every cover premium. has 2 decimals. eg.: 10.00% stored as 1000
    */
    uint256 public feePercentage;
    bool public buysAllowed;
    /*
      address where `buyCover` distributor fees and `ethOut` from `sellNXM` are sent. Controlled by Owner.
    */
    address payable public treasury;

    /*
      NexusMutual contracts
    */
    IGateway public gateway;
    IERC20Upgradeable public nxmToken;
    INXMaster public master;

    modifier onlyTokenApprovedOrOwner(uint256 tokenId) {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Distributor: Not approved or owner"
        );
        _;
    }

    /**
     * @dev Standard pattern of constructing proxy contracts with the same signature as the constructor.
     */
    function initialize(
        address gatewayAddress,
        address nxmTokenAddress,
        address masterAddress,
        uint256 _feePercentage,
        address payable _treasury,
        string memory tokenName,
        string memory tokenSymbol
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC721_init(tokenName, tokenSymbol);

        _setBaseURI(DEFAULT_BASE_URI);
        buysAllowed = true;
        feePercentage = _feePercentage;
        treasury = _treasury;
        gateway = IGateway(gatewayAddress);
        nxmToken = IERC20Upgradeable(nxmTokenAddress);
        master = INXMaster(masterAddress);
    }

    /**
     * @dev buy cover for a coverable identified by its contractAddress
     * @param contractAddress contract address of coverable
     * @param coverAsset asset of the premium and of the sum assured.
     * @param sumAssured amount payable if claim is submitted and considered valid
     * @param coverType cover type dermining how the data parameter is decoded
     * @param maxPriceWithFee max price (including fee) to be spent on the cover.
     * @param data abi-encoded field with additional cover data fields
     * @return token id
     */
    function buyCover(
        address contractAddress,
        address coverAsset,
        uint256 sumAssured,
        uint16 coverPeriod,
        uint8 coverType,
        uint256 maxPriceWithFee,
        bytes calldata data
    ) external payable nonReentrant returns (uint256) {
        require(buysAllowed, "Distributor: buys not allowed");

        uint256 coverPrice = gateway.getCoverPrice(
            contractAddress,
            coverAsset,
            sumAssured,
            coverPeriod,
            IGateway.CoverType(coverType),
            data
        );
        uint256 coverPriceWithFee = feePercentage
            .mul(coverPrice)
            .div(10000)
            .add(coverPrice);
        require(
            coverPriceWithFee <= maxPriceWithFee,
            "Distributor: cover price with fee exceeds max"
        );

        uint256 buyCoverValue = 0;
        if (coverAsset == ETH) {
            require(
                msg.value >= coverPriceWithFee,
                "Distributor: Insufficient ETH sent"
            );
            uint256 remainder = msg.value.sub(coverPriceWithFee);

            if (remainder > 0) {
                // solhint-disable-next-line avoid-low-level-calls
                (
                    bool ok, /* data */

                ) = address(msg.sender).call{value: remainder}("");
                require(
                    ok,
                    "Distributor: Returning ETH remainder to sender failed."
                );
            }

            buyCoverValue = coverPrice;
        } else {
            IERC20Upgradeable token = IERC20Upgradeable(coverAsset);
            token.safeTransferFrom(
                msg.sender,
                address(this),
                coverPriceWithFee
            );
            token.approve(address(gateway), coverPrice);
        }

        uint256 coverId = gateway.buyCover{value: buyCoverValue}(
            contractAddress,
            coverAsset,
            sumAssured,
            coverPeriod,
            IGateway.CoverType(coverType),
            data
        );

        {
            uint256 fee = coverPriceWithFee.sub(coverPrice);
            if (fee > 0) {
                transferToTreasury(fee, coverAsset);
            }
        }

        // mint token using the coverId as a tokenId (guaranteed unique)
        _mint(msg.sender, coverId);

        {
            emit BuyCoverEvent(
                contractAddress,
                coverId,
                coverPeriod,
                coverAsset,
                sumAssured,
                coverPriceWithFee
            );
        }

        return coverId;
    }

    /**
     * @notice Submit a claim for the cover
     * @param tokenId cover token id
     * @param data abi-encoded field with additional claim data fields
     */
    function submitClaim(uint256 tokenId, bytes calldata data)
        external
        onlyTokenApprovedOrOwner(tokenId)
        returns (uint256)
    {
        // coverId = tokenId
        uint256 claimId = gateway.submitClaim(tokenId, data);
        emit ClaimSubmitted(tokenId, claimId, msg.sender);
        return claimId;
    }

    /**
     * @notice Redeem the claim to the cover. Requires that that the payout is completed.
     * @param tokenId cover token id
     */
    function redeemClaim(uint256 tokenId, uint256 claimId)
        public
        onlyTokenApprovedOrOwner(tokenId)
        nonReentrant
    {
        uint256 coverId = gateway.getClaimCoverId(claimId);
        require(coverId == tokenId, "Distributor: coverId claimId mismatch");
        (
            IGateway.ClaimStatus status,
            uint256 amountPaid,
            address coverAsset
        ) = gateway.getPayoutOutcome(claimId);
        require(
            status == IGateway.ClaimStatus.ACCEPTED,
            "Distributor: Claim not accepted"
        );

        _burn(tokenId);
        if (coverAsset == ETH) {
            (
                bool ok, /* data */

            ) = msg.sender.call{value: amountPaid}("");
            require(ok, "Distributor: Transfer to NFT owner failed");
        } else {
            IERC20Upgradeable erc20 = IERC20Upgradeable(coverAsset);
            erc20.safeTransfer(msg.sender, amountPaid);
        }

        emit ClaimPayoutRedeemed(
            tokenId,
            claimId,
            msg.sender,
            amountPaid,
            coverAsset
        );
    }

    /**
    * @notice Execute an action on specific cover token. The action is identified by an `action` id.
      Allows for an ETH transfer or an ERC20 transfer.
      If less than the supplied assetAmount is needed, it is returned to `msg.sender`.
  * @dev The purpose of this function is future-proofing for updates to the cover buy->claim cycle.
  * @param tokenId id of the cover token
  * @param assetAmount optional asset amount to be transferred along with the action executed
  * @param asset optional asset to be transferred along with the action executed
  * @param action action identifier
  * @param data abi-encoded field with action parameters
  * @return response (abi-encoded response, amount withheld from the original asset amount supplied)
  */
    function executeCoverAction(
        uint256 tokenId,
        uint256 assetAmount,
        address asset,
        uint8 action,
        bytes calldata data
    )
        external
        payable
        onlyTokenApprovedOrOwner(tokenId)
        nonReentrant
        returns (bytes memory response, uint256 withheldAmount)
    {
        if (assetAmount == 0) {
            return gateway.executeCoverAction(tokenId, action, data);
        }
        if (asset == ETH) {
            require(
                msg.value >= assetAmount,
                "Distributor: Insufficient ETH sent"
            );
            (response, withheldAmount) = gateway.executeCoverAction{
                value: msg.value
            }(tokenId, action, data);
            uint256 remainder = assetAmount.sub(withheldAmount);
            (
                bool ok, /* data */

            ) = address(msg.sender).call{value: remainder}("");
            require(
                ok,
                "Distributor: Returning ETH remainder to sender failed."
            );
            return (response, withheldAmount);
        }

        IERC20Upgradeable token = IERC20Upgradeable(asset);
        token.safeTransferFrom(msg.sender, address(this), assetAmount);
        token.approve(address(gateway), assetAmount);
        (response, withheldAmount) = gateway.executeCoverAction(
            tokenId,
            action,
            data
        );
        uint256 remainder = assetAmount.sub(withheldAmount);
        token.safeTransfer(msg.sender, remainder);
        return (response, withheldAmount);
    }

    /**
     * @notice get cover data
     * @param tokenId cover token id
     */
    function getCover(uint256 tokenId)
        public
        view
        returns (
            uint8 status,
            uint256 sumAssured,
            uint16 coverPeriod,
            uint256 validUntil,
            address contractAddress,
            address coverAsset,
            uint256 premiumInNXM,
            address memberAddress
        )
    {
        return gateway.getCover(tokenId);
    }

    /**
     * @notice get state of a claim payout. Returns
     * status of cover,  amount paid as part of the payout, address of the cover asset)
     * @param claimId id of claim
     */
    function getPayoutOutcome(uint256 claimId)
        public
        view
        returns (
            IGateway.ClaimStatus status,
            uint256 amountPaid,
            address coverAsset
        )
    {
        (status, amountPaid, coverAsset) = gateway.getPayoutOutcome(claimId);
    }

    /**
     * @notice Set `amount` as the allowance of `spender` over the distributor's NXM tokens.
     * @param spender approved spender
     * @param amount amount approved
     */
    function approveNXM(address spender, uint256 amount) public onlyOwner {
        nxmToken.approve(spender, amount);
    }

    /**
     * @notice Moves `amount` tokens from the distributor to `recipient`.
     * @param recipient recipient of NXM
     * @param amount amount of NXM
     */
    function withdrawNXM(address recipient, uint256 amount) public onlyOwner {
        nxmToken.transfer(recipient, amount);
    }

    /**
     * @notice Switch NexusMutual membership to `newAddress`.
     * @param newAddress address
     */
    function switchMembership(address newAddress) external onlyOwner {
        nxmToken.approve(address(gateway), uint256(-1));
        gateway.switchMembership(newAddress);
    }

    /**
     * @notice Sell Distributor-owned NXM tokens for ETH
     * @param nxmIn Amount of NXM to sell
     * @param minEthOut minimum expected Eth received
     */
    function sellNXM(uint256 nxmIn, uint256 minEthOut) external onlyOwner {
        address poolAddress = master.getLatestAddress("P1");
        nxmToken.approve(poolAddress, nxmIn);
        uint256 balanceBefore = address(this).balance;
        IPool(poolAddress).sellNXM(nxmIn, minEthOut);
        uint256 balanceAfter = address(this).balance;

        transferToTreasury(balanceAfter.sub(balanceBefore), ETH);
    }

    /**
     * @notice Set if buyCover calls are allowed (true) or not (false).
     * @param _buysAllowed value set for buysAllowed
     */
    function setBuysAllowed(bool _buysAllowed) external onlyOwner {
        buysAllowed = _buysAllowed;
    }

    /**
     * @notice Set treasury address where `buyCover` distributor fees and `ethOut` from `sellNXM` are sent.
     * @param _treasury new treasury address
     */
    function setTreasury(address payable _treasury) external onlyOwner {
        treasury = _treasury;
    }

    /**
     * @notice Send `amount` of `asset`  to treasury address
     * @param amount amount of asset
     * @param asset ERC20 token address or ETH
     */
    function transferToTreasury(uint256 amount, address asset) internal {
        if (asset == ETH) {
            (
                bool ok, /* data */

            ) = treasury.call{value: amount}("");
            require(ok, "Distributor: Transfer to treasury failed");
        } else {
            IERC20Upgradeable erc20 = IERC20Upgradeable(asset);
            erc20.safeTransfer(treasury, amount);
        }
    }

    /**
     * @notice Set fee percentage for buyCover premiums.
     *  `_feePercentage` has 2 decimals of precision ( 5000 is 50%)
     * @param _feePercentage fee percentage to be set
     */
    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        feePercentage = _feePercentage;
    }

    /**
     * @dev required to be allow for receiving ETH claim payouts
     */
    receive() external payable {}

    /**
     * @dev Function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }
}