// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender)
        external
        view
        returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

/**
 * @title CCSwapClaimA
 * @author ClearCryptos Blockchain Team - G3NOM3
 */
contract CCSwapClaimA is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using SafeMathUpgradeable for uint256;

    address payable private s_receivingWallet;
    address private s_tokenWallet;

    IUniswapV2Pair private s_pair;
    IERC20Upgradeable private s_token;

    bool private s_paused;
    mapping(address => bool) private s_isOperational;
    mapping(address => bool) private s_isBlacklisted;
    bool private s_bonusActivated;

    /**
     * Event for token purchase logging
     * @param purchaser who purchased the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(
        address indexed purchaser,
        uint256 value,
        uint256 amount
    );

    /**
     * @param _receivingWallet Address where collected eth will be forwarded to
     * @param _tokenWallet Address from where the tokens are transfered
     * @param _token Address of the token being sold
     * @param _pair Address of the pair
     */
    function initialize(
        address payable _receivingWallet,
        address _tokenWallet,
        address _token,
        address _pair
    ) public initializer {
        require(
            _receivingWallet != address(0),
            "Receiving wallet cannot be the zero address"
        );
        require(
            _tokenWallet != address(0),
            "Token wallet cannot be the zero address"
        );
        require(
            _token != address(0),
            "Token address cannot be the zero address"
        );
        require(_pair != address(0), "Pair address cannot be the zero address");

        s_receivingWallet = _receivingWallet;
        s_tokenWallet = _tokenWallet;
        s_token = IERC20Upgradeable(_token);
        s_pair = IUniswapV2Pair(_pair);
        s_paused = true;
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer eth with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */
    receive() external payable {
        buyTokens();
    }

    /**
     * @return s_token token being sold.
     */
    function token() public view returns (IERC20Upgradeable) {
        return s_token;
    }

    /**
     * @dev Set new sold token
     * @param _token address of the new sold token
     */
    function setToken(address _token) external onlyOwner {
        require(_token != address(0), "Zero address cannot be token");
        s_token = IERC20Upgradeable(_token);
    }

    /**
     * @return s_receivingWallet address where eth is collected
     */
    function receivingWallet() public view returns (address payable) {
        return s_receivingWallet;
    }

    /**
     * @dev Set new receiving wallet
     * @param _receivingWallet address of the new receiving wallet
     */
    function setReceivingWallet(address payable _receivingWallet)
        external
        onlyOwner
    {
        require(
            _receivingWallet != address(0),
            "Zero address cannot be receiving wallet"
        );
        s_receivingWallet = _receivingWallet;
    }

    /**
     * @return s_tokenWallet address of the wallet that will hold the tokens.
     */
    function tokenWallet() public view returns (address) {
        return s_tokenWallet;
    }

    /**
     * @dev Set new token wallet
     * @param _tokenWallet address of the new token wallet
     */
    function setTokenWallet(address _tokenWallet) external onlyOwner {
        require(
            _tokenWallet != address(0),
            "Zero address cannot be token wallet"
        );
        s_tokenWallet = _tokenWallet;
    }

    /**
     * @return s_pair address of the pair
     */
    function pair() public view returns (IUniswapV2Pair) {
        return s_pair;
    }

    /**
     * @dev Set new pair
     * @param _pair address of the new pair
     */
    function setPair(address _pair) external onlyOwner {
        require(_pair != address(0), "Zero address cannot be pair");
        s_pair = IUniswapV2Pair(_pair);
    }

    /**
     * @return paused activity state of the swap / claim
     */
    function paused() public view returns (bool) {
        return s_paused;
    }

    /**
     * @dev Set new activity state of the swap / claim
     * @param _paused new activity state
     */
    function setPaused(bool _paused) external onlyOwner {
        require(s_paused != _paused, "Value already set");
        s_paused = _paused;
    }

    /**
     * @return s_bonusActivated activity state of bonus
     */
    function bonusActivated() public view returns (bool) {
        return s_bonusActivated;
    }

    /**
     * @dev Set new activity state of bonus
     * @param _bonusActivated new activity state of bonus
     */
    function setBonusActivated(bool _bonusActivated) external onlyOwner {
        require(s_bonusActivated != _bonusActivated, "Value already set");
        s_bonusActivated = _bonusActivated;
    }

    /**
     * @dev Checks if the input address is an operations provider.
     *
     * @param _operationalAddress is a possible operations provider's address.
     */
    function isOperational(address _operationalAddress)
        external
        view
        virtual
        returns (bool)
    {
        return s_isOperational[_operationalAddress];
    }

    /**
     * @dev Add Operational Address.
     * @param _operationalAddress is a new operations provider's address.
     */
    function setOperational(address _operationalAddress)
        external
        virtual
        onlyOwner
    {
        require(
            _operationalAddress != address(0),
            "Zero address cannot be operational"
        );
        s_isOperational[_operationalAddress] = true;
    }

    /**
     * @dev Remove Operational Address
     *
     * @param _operationalAddress is an existing operations provider's address.
     */
    function removeOperational(address _operationalAddress)
        external
        virtual
        onlyOwner
    {
        delete s_isOperational[_operationalAddress];
    }

    /**
     * @dev Checks if an address is blacklisted
     *
     * @param _blacklistedAddress is a possible blacklisted address
     */
    function isBlacklisted(address _blacklistedAddress)
        external
        view
        virtual
        returns (bool)
    {
        return s_isBlacklisted[_blacklistedAddress];
    }

    /**
     * @dev Add new Blacklisted Address
     *
     * Requirements:
     *
     * - `_blacklistedAddress` cannot be the zero address.
     *
     * @param _blacklistedAddress is a new blacklisted address.
     */
    function setBlacklisted(address _blacklistedAddress)
        external
        virtual
        onlyOwner
    {
        require(
            _blacklistedAddress != address(0),
            "Zero address cannot be blacklisted"
        );
        s_isBlacklisted[_blacklistedAddress] = true;
    }

    /**
     * @dev Remove Blacklisted Address
     *
     * @param _blacklistedAddress is an existing blacklisted address
     */
    function removeBlacklisted(address _blacklistedAddress)
        external
        virtual
        onlyOwner
    {
        delete s_isBlacklisted[_blacklistedAddress];
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     */
    function buyTokens() public payable nonReentrant {
        if (!s_isOperational[msg.sender]) {
            require(s_paused == false, "Activity paused");
        }
        uint256 weiAmount = msg.value;
        address beneficiary = msg.sender;
        _preValidatePurchase(beneficiary, weiAmount);

        uint256 tokens = _getTokenAmount(weiAmount);

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }

    /**
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount)
        internal
        view
        virtual
    {
        require(
            beneficiary != address(0),
            "beneficiary cannot be the zero address"
        );
        require(!s_isBlacklisted[beneficiary], "The address is blacklisted");
        require(weiAmount != 0, "weiAmount is 0");
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(address beneficiary, uint256 weiAmount)
        internal
        view
    {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        s_token.transferFrom(s_tokenWallet, beneficiary, tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount)
        internal
    {
        _deliverTokens(beneficiary, tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount)
        internal
    {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return tokenAmount Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount)
        internal
        view
        returns (uint256)
    {
        (uint Res0, uint Res1, ) = s_pair.getReserves();
        uint256 tokenAmount;
        if (s_pair.token0() == address(s_token)) {
            tokenAmount = weiAmount.mul(Res0).div(Res1);
        } else {
            tokenAmount = weiAmount.mul(Res1).div(Res0);
        }

        if (s_isOperational[msg.sender] || s_bonusActivated) {
            uint256 bonusRatio = getBonusRatio();
            tokenAmount = tokenAmount + tokenAmount.mul(bonusRatio).div(1000);
        }

        return tokenAmount;
    }

    /**
     * @dev Get the bonus ratio
     * @return bonusRatio The ratio of tokens received as bonus
     */
    function getBonusRatio() public view returns (uint256) {
        uint256 bonusRatio = 0;
        uint256 balanceOfTokenWallet = s_token.balanceOf(s_tokenWallet);
        uint256 valueofTokenWallet;

        (uint Res0, uint Res1, ) = s_pair.getReserves();
        if (s_pair.token0() == address(s_token)) {
            valueofTokenWallet = balanceOfTokenWallet.mul(Res1).div(Res0);
        } else {
            valueofTokenWallet = balanceOfTokenWallet.mul(Res0).div(Res1);
        }

        if (valueofTokenWallet > 320 ether) {
            bonusRatio = 50;
        } else if (valueofTokenWallet > 160 ether) {
            bonusRatio = 30;
        } else if (valueofTokenWallet > 65 ether) {
            bonusRatio = 15;
        }

        return bonusRatio;
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        s_receivingWallet.transfer(msg.value);
    }
}