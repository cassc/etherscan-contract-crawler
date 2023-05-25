// // // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./helpers/SniperStructs.sol";
import "./helpers/IWETH.sol";
import "./helpers/IPunk.sol";
import "./helpers/SniperErrors.sol";
import "solmate/src/auth/Owned.sol";
import "openzeppelin/contracts/token/ERC721/IERC721.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title AutoSniper 2.0 for @oSnipeNFT
 * @author 0xQuit
 */

/*

        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*+=--::::::--=+*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*=:.       ......        :=*%@@@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=.    .-+*%@@@@@@@@@@@@%#+=:    [email protected]@@@@@=:::=#@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@%+.   :=#@@@@@@@@@@@@@@@@@@@@@@@@#+#@@@@@%**+-:::-%@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@#-   :+%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%******+-::[email protected]@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@%:   =%@@@@@@@@@@@@@@@@%%%%@@@@@@@@@@@@@@%*++++++***[email protected]@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@=   [email protected]@@@@@@@@@@@#+-:.         :-+%@@@@@%*+++++++++*#@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@#.  :%@@@@@@@@@%+:      ..:::::.  .*@@@%*+++++++++++#@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@*   [email protected]@@@@@@@@#:    .=*%@@@@@@@@@@%@@@%+----======+#@@@@@%@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@+   *@@@@@@@@#:   .+%@@@@@@@@@@@@@@@@@@=-------==+#@@@@@%- [email protected]@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@#   #@@@@@@@@=   .*@@@@@@@@@#=.    .-+#+=--------*@@@@@@@%   [email protected]@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@.  [email protected]@@@@@@@-   [email protected]@@@@@@@@@:  -+**+-   .--=----+%@@@@@@@@@#   %@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@+  [email protected]@@@@@@@-   [email protected]@@@@@@@@@-  #@@@@%+-:.  :=*@#%@@@*%@@@@@@@=  [email protected]@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@.  #@@@@@@@+   [email protected]@@@@@@@@@@:  @@@%=-----.  #@@@@@*. [email protected]@@@@@@@   %@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@#   @@@@@@@@.  [email protected]@@@@@@@@@@@%  :#=:::::--*[email protected]@@@@@-   %@@@@@@@-  [email protected]@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@+  :@@@@@@@%   [email protected]@@@@@@@@@@@@%-:--::::-*@@@@@@@@@@*   *@@@@@@@+  :@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@=  [email protected]@@@@@@#   [email protected]@@@@@@@@@@@@#-:---:-*@@@@@@@@@@@@#   [email protected]@@@@@@+  :@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@+  [email protected]@@@@@@%   [email protected]@@@@@*#@@@#-::---=. [email protected]@@@@@@@@@@@*   [email protected]@@@@@@+  :@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@#  [email protected]@@@@@@@   [email protected]@@@@+  #*-:::--*@@#  [email protected]@@@@@@@@@@-   %@@@@@@@-  [email protected]@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@   #@@@@@@@+  [email protected]@@@@%  .--:[email protected]@@@@=  %@@@@@@@@@#   :@@@@@@@@   %@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@=  :@@@@@@@@=%@@@@@@*:   :-*@@@@@@%. [email protected]@@@@@@@@%    %@@@@@@@=  :@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@   [email protected]@@@@@@@@@@@#+---:.  .=*###*-  :%@@@@@@@@#   .%@@@@@@@#   #@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@*   %@@@@@@@@@#=------*%+-      .-#@@@@@@@@%=   .%@@@@@@@@.  [email protected]@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@= .*@@@@@@@@+------=%@@@@@@%%%@@@@@@@@@@#-    [email protected]@@@@@@@@:  :@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@#@@@@@@@@*===---=#@@@@@@@@@@@@@@@@@%*-     [email protected]@@@@@@@@#   [email protected]@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@*=====+#%@@@@@%= .:--==--:.     .-*@@@@@@@@@@+   [email protected]@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@+--==+#@@@@@@@@=:.           :=*%@@@@@@@@@@@*.  .#@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@*===+-*@@@@@@@@@@@@@@%%#####%@@@@@@@@@@@@@@@*.   [email protected]@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@#+==#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=   [email protected]@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@+==+%@@@@@@@@@%*%@@@@@@@@@@@@@@@@@@@@@@@@@*-    -*@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@#=%@@@@@@@@@+    -=*%@@@@@@@@@@@@@@%*+-.    :[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%+-.      ..:::::::.      .-+#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*+=-:........:-=+*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

*/

contract AutoSniper is Owned {
    event Snipe(
        SniperOrder order,
        Claim[] claims
    );

    event Deposit(
        address sniper,
        uint256 amount
    );

    event Withdrawal(
        address sniper,
        uint256 amount
    );

    string public constant name = "oSnipe: AutoSniper V2";

    address private constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private fulfillerAddress = 0x816B65bd147df5C2566d2C9828815E85ff6055c6;
    address public nextContractVersionAddress;
    bool public migrationEnabled;
    mapping(address => bool) public allowedMarketplaces;
    mapping(address => uint256) public sniperBalances;
    mapping(address => SniperGuardrails) public sniperGuardrails;

    constructor() Owned(0x507c8252c764489Dc1150135CA7e41b01e10ee74) {}

    /**
    * @dev fulfillOrder conducts its own checks to ensure that the passed order is a valid sniper
    * before forwarding the snipe on to the appropriate marketplace. Snipers can block orders by setting
    * up guardrails that prevent orders from being fulfilled outside of allowlisted marketplaces or
    * nft contracts, or with tips that exceed a maximum tip amount. WETH is used to subsidize
    * the order in case the Sniper's deposited balance is too low. WETH must be approved in order for this to
    * work. Calculation is done off-chain and passed in via wethAmount. If for some reason there is an overpay,
    * the marketplace will refund the difference, which is added to the Sniper's balance.
    * @param wethSubsidy the amount of WETH that needs to be converted.
    * @param claims an array of claims that the sniped NFT is eligible for. Claims are claimed and
    * transferred to the sniper along with the sniped NFT.
    */
    function fulfillOrder(SniperOrder calldata order, Claim[] calldata claims, uint256 wethSubsidy) external onlyFulfiller {
        _checkGuardrails(order.tokenAddress, order.marketplace, order.autosniperTip, order.to);
        uint256 totalValue = order.value + order.autosniperTip + order.validatorTip;
        if (wethSubsidy > 0) _swapWeth(wethSubsidy, order.to);
        if (sniperBalances[order.to] < totalValue) revert InsufficientBalance();

        uint256 balanceBefore = address(this).balance;

        (bool autosniperPaid, ) = payable(fulfillerAddress).call{value: order.autosniperTip}("");
        if (!autosniperPaid) revert FailedToPayAutosniper();
        (bool orderFilled,) = order.marketplace.call{value: order.value}(order.data);
        if (!orderFilled) revert OrderFailed();
        (bool validatorPaid, ) = block.coinbase.call{value: order.validatorTip}("");
        if (!validatorPaid) revert FailedToPayValidator();

        uint256 balanceAfter = address(this).balance;
        uint256 spent = balanceBefore - balanceAfter;

        sniperBalances[order.to] -= spent;

        _claimAndTransferClaimableAssets(claims, order.to);
        _transferNftToSniper(order.tokenType, order.tokenAddress, order.tokenId, address(this), order.to);
        emit Snipe(order, claims);
    }

    /**
    * @dev fulfillNonCompliantMarketplaceOrder is a variant on fulfillOrder, used for markets that
    * don't allow purchases through contracts. The fulfiller EOA will fulfill the order, and then use
    * this function to get it to the sniper.
    * @param wethSubsidy the amount of WETH that needs to be converted.
    * @param claims an array of claims that the sniped NFT is eligible for. Claims are claimed and
    * transferred to the sniper along with the sniped NFT.
    */
    function fulfillNonCompliantMarketplaceOrder(SniperOrder calldata order, Claim[] calldata claims, uint256 wethSubsidy) external onlyFulfiller {
        _checkGuardrails(order.tokenAddress, order.marketplace, order.autosniperTip, order.to);
        uint256 totalValue = order.value + order.autosniperTip + order.validatorTip;
        if (wethSubsidy > 0) _swapWeth(wethSubsidy, order.to);
        if (sniperBalances[order.to] < totalValue) revert InsufficientBalance();

        uint256 balanceBefore = address(this).balance;

        (bool autosniperPaid, ) = payable(fulfillerAddress).call{value: order.autosniperTip + order.value}("");
        if (!autosniperPaid) revert FailedToPayAutosniper();
        (bool validatorPaid, ) = block.coinbase.call{value: order.validatorTip}("");
        if (!validatorPaid) revert FailedToPayValidator();

        uint256 balanceAfter = address(this).balance;
        uint256 spent = balanceBefore - balanceAfter;

        sniperBalances[order.to] -= spent;

        _transferNftToSniper(order.tokenType, order.tokenAddress, order.tokenId, fulfillerAddress, order.to);

        emit Snipe(order, claims);
    }

    /**
    * @dev solSnatch is a pure arbitrage function for fulfilling an order, and accepting a WETH offer in the same transaction.
    * Contract balance can be used, but user balances cannot be affected - the call will revert if the post-call contract
    * balance is lower than the pre-call balance.
    * @param contractAddresses a list of contract addresses that will be called
    * @param calls a matching array to contractAddresses, each index being a call to make to a given contract
    * @param validatorTip the amount to send to block.coinbase. Reverts if this is 0.
    */
    function solSnatch(address[] calldata contractAddresses, bytes[] calldata calls, uint256[] calldata values, address sniper, uint256 validatorTip, uint256 fulfillerTip) external onlyFulfiller {
        if (contractAddresses.length != calls.length) revert ArrayLengthMismatch();
        if (calls.length != values.length) revert ArrayLengthMismatch();
        uint256 balanceBefore = address(this).balance;

        for (uint256 i = 0; i < contractAddresses.length;) {
            (bool success, ) = contractAddresses[i].call{value: values[i]}(calls[i]);
            if (!success) revert OrderFailed();

            unchecked { ++i; }
        }

        (bool validatorPaid, ) = block.coinbase.call{value: validatorTip}("");
        if (!validatorPaid) revert FailedToPayValidator();
        (bool fulfillerPaid, ) = fulfillerAddress.call{value: fulfillerTip}("");
        if (!fulfillerPaid) revert FailedToPayAutosniper();

        uint256 balanceAfter = address(this).balance;

        if (balanceAfter <= balanceBefore) revert NoMoneyMoProblems();
        sniperBalances[sniper] += balanceAfter - balanceBefore;

        emit Deposit(sniper, balanceAfter - balanceBefore);
    }

    /**
    * @dev In cases where we execute a snipe without using this contract, use this function as a solution to
    * bypass priority fee by tipping the coinbase directly, and emit Snipe event for logging purposes.
    * @param order this order contains a validator tip which is paid out, and is emitted in the Snipe event
    * @param claims these claims are unused, but are included in the event and should reflect the claims executed
    * as part of the snipe prior to calling this function.
    */
    function sendDirectTipToCoinbase(SniperOrder calldata order, Claim[] calldata claims) external payable onlyFulfiller {
        (bool validatorPaid, ) = block.coinbase.call{value: order.validatorTip}("");
        if (!validatorPaid) revert FailedToPayValidator();

        emit Snipe(order, claims);
    }

    /**
    * @dev deposit Ether into the contract. 
    * @param sniper is the address who's balance is affected.
    */
    function deposit(address sniper) public payable {
        sniperBalances[sniper] += msg.value;

        emit Deposit(sniper, msg.value);
    }

    /**
    * @dev deposit Ether into your own contract balance.
    */
    function depositSelf() external payable {
        deposit(msg.sender);
    }

    /**
    * @dev withdraw Ether from your contract balance
    * @param amount the amount of Ether to be withdrawn 
    */
    function withdraw(uint256 amount) external {
        if (sniperBalances[msg.sender] < amount) revert InsufficientBalance();
        sniperBalances[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert FailedToWithdraw();

        emit Withdrawal(msg.sender, amount);
    }

    /**
    * @dev set up a marketplace allowlist.
    * @param guardEnabled if false then marketplace allowlist will not be checked for this user
    * @param marketplaceAllowed boolean indicating whether the marketplace is allowed or not
    */
    function setUserAllowedMarketplaces(bool guardEnabled, bool marketplaceAllowed, address[] calldata marketplaces) external {
        sniperGuardrails[msg.sender].marketplaceGuardEnabled = guardEnabled;
        for (uint256 i = 0; i < marketplaces.length;) {
            sniperGuardrails[msg.sender].allowedMarketplaces[marketplaces[i]] = marketplaceAllowed;
            unchecked { ++i; }
        }
    }

    /**
    * @dev Set up a maximum tip guardrail (in wei). If set to 0, guardrail will be disabled.
    */
    function setUserMaxTip(uint256 maxTipInWei) external {
        sniperGuardrails[msg.sender].maxTip = maxTipInWei;
    }

    /**
    * @dev set up NFT contract allowlist
    * @param guardEnabled if false then NFT contract allowlist will not be checked for this user
    * @param nftAllowed boolean indicating whether the NFT contract is allowed or not
    */
    function setUserAllowedNfts(bool guardEnabled, bool nftAllowed, address[] calldata nfts) external {
        sniperGuardrails[msg.sender].nftContractGuardEnabled = guardEnabled;
        for (uint256 i = 0; i < nfts.length;) {
            sniperGuardrails[msg.sender].allowedNftContracts[nfts[i]] = nftAllowed;
            unchecked { ++i; }
        }
    }

    /**
    * @dev Owner function to set up global marketplace allowlist.
    */
    function configureMarkets(address[] calldata marketplaces, bool status) external onlyOwner {
        for (uint256 i = 0; i < marketplaces.length;) {
            allowedMarketplaces[marketplaces[i]] = status;

            unchecked { ++i; }
        }
    }

    /**
    * @dev Owner function to change fulfiller address if needed.
    */
    function setFulfillerAddress(address _fulfiller) external onlyOwner {
        fulfillerAddress = _fulfiller;
    }

    /**
    * Enables migration and sets a destination address (the new contract)
    * @param _destination the new AutoSniper version to allow migration to.
    */
    function setMigrationAddress(address _destination) external onlyOwner {
        migrationEnabled = true;
        nextContractVersionAddress = _destination;
    }

    // getters to simplify web3js calls
    function marketplaceApprovedBySniper(address sniper, address marketplace) external view returns (bool) {
        return sniperGuardrails[sniper].allowedMarketplaces[marketplace];
    }

    function nftContractApprovedBySniper(address sniper, address nftContract) external view returns (bool) {
        return sniperGuardrails[sniper].allowedNftContracts[nftContract];
    }

    /**
    * @dev in the event of a future contract upgrade, this function allows snipers to
    * easily move their ether balance to the new contract. This can only be called by
    * the sniper to move their personal balance - the contract owner or anybody else
    * does not have the power to migrate balances for users.
    */
    function migrateBalance() external {
        if (!migrationEnabled) revert MigrationNotEnabled();
        uint256 balanceToMigrate = sniperBalances[msg.sender];
        sniperBalances[msg.sender] = 0;

        (bool success, ) = nextContractVersionAddress.call{value: balanceToMigrate}(abi.encodeWithSelector(this.deposit.selector, msg.sender));
        if (!success) revert FailedToWithdraw();
    }

    // internal helpers
    function _swapWeth(uint256 wethAmount, address sniper) private onlyFulfiller {
        IWETH weth = IWETH(WETH_ADDRESS);
        weth.transferFrom(sniper, address(this), wethAmount);
        weth.withdraw(wethAmount);

        unchecked { sniperBalances[sniper] += wethAmount; }
    }

    function _transferNftToSniper(ItemType tokenType, address tokenAddress, uint256 tokenId, address source, address sniper) private {
        if (tokenType == ItemType.ERC721) {
            IERC721(tokenAddress).transferFrom(source, sniper, tokenId);
        } else if (tokenType == ItemType.ERC1155) {
            IERC1155(tokenAddress).safeTransferFrom(source, sniper, tokenId, 1, "");
        } else if (tokenType == ItemType.CRYPTOPUNKS) {
            IPunk(tokenAddress).transferPunk(sniper, tokenId);
        } else if (tokenType == ItemType.ERC20) {
            IERC20 token = IERC20(tokenAddress);
            token.transfer(sniper, token.balanceOf(source));
        }
    }

    function _claimAndTransferClaimableAssets(Claim[] calldata claims, address sniper) private {
        for (uint256 i = 0; i < claims.length; i++) {
            Claim memory claim = claims[i];

            (bool claimSuccess, ) = claim.tokenAddress.call(claim.claimData);
            if (!claimSuccess) revert ClaimFailed();

            _transferNftToSniper(claim.tokenType, claim.tokenAddress, claim.tokenId, address(this), sniper);
        }
    }

    function _checkGuardrails(address tokenAddress, address marketplace, uint256 tip, address sniper) private view {
        SniperGuardrails storage guardrails = sniperGuardrails[sniper];

        if (!allowedMarketplaces[marketplace]) revert MarketplaceNotAllowed();
        if (guardrails.maxTip > 0 && tip > guardrails.maxTip) revert MaxTipExceeded();
        if (guardrails.marketplaceGuardEnabled && !guardrails.allowedMarketplaces[marketplace]) revert MarketplaceNotAllowed();
        if (guardrails.nftContractGuardEnabled && !guardrails.allowedNftContracts[tokenAddress]) revert TokenContractNotAllowed();
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return 0x150b7a02;
    }

    // Used by ERC721BasicToken.sol
    function onERC721Received(
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return 0xf0b9e5ba;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        virtual
        view
        returns (bool)
    {
        return interfaceId == this.supportsInterface.selector;
    }

    receive() external payable {}

    // Emergency function: In case any ERC20 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC20(address asset, address recipient) onlyOwner external {
        IERC20 token = IERC20(asset);
        token.transfer(recipient, token.balanceOf(address(this)));
    }

    // Emergency function: In case any ERC721 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC721(address asset, uint256[] calldata ids, address recipient) onlyOwner external {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721(asset).transferFrom(address(this), recipient, ids[i]);
        }
    }

    // Emergency function: In case any ERC1155 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC1155(address asset, uint256[] calldata ids, uint256[] calldata amounts, address recipient) onlyOwner external {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC1155(asset).safeTransferFrom(address(this), recipient, ids[i], amounts[i], "");
        }
    }

    modifier onlyFulfiller() {
        if (msg.sender != fulfillerAddress) revert CallerNotFulfiller();
        _;
    }
}