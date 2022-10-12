// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "./interfaces/IBentoBoxFactory.sol";
import "./interfaces/IMisoMarket.sol";
import "./INFPreIPOToken.sol";
import "./interfaces/IINFPermissionManager.sol";
import "./CrowdSale/interfaces/IPointList.sol";

interface IPermit {
    function permit(
            address owner,
            address spender,
            uint256 value,
            uint256 deadline,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) external;
}
interface ISwapRouter {
    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);
}

contract INFFactory is AccessControlEnumerable {
    using SafeERC20 for IERC20;

    // Issuer currently can only issue new tokens/certs, but cannot manage other owners'
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    mapping(string => address) public tokens;
    string[] public tokenSymbols;

    address public immutable marketTemplate;

    /// @notice Auctions created using factory.
    mapping(IERC20 => address[]) public auctions;

    ISwapRouter private constant SWAP_ROUTER = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    IINFPermissionManager public immutable permissionManager;
    IPointList public immutable pointListAdapter;
    IBentoBoxFactory public immutable bentoBox;

    /// @notice Event emitted when auction is created using template id.
    event MarketCreated(address indexed owner, address indexed addr, address indexed marketTemplate);

    constructor(address marketTemplate_, IINFPermissionManager _permissionManager, IPointList _pointListAdapter, IBentoBoxFactory _bentoBox, address to) {
        _setupRole(DEFAULT_ADMIN_ROLE, to);
        _setupRole(ISSUER_ROLE, to);

        marketTemplate = marketTemplate_;
        permissionManager = _permissionManager;
        pointListAdapter = _pointListAdapter;
        bentoBox = _bentoBox;
    }

    function issue(
        string memory name,
        string memory symbol,
        uint256 shares,
        address tradingToken
    )
        public
        onlyRole(ISSUER_ROLE) returns (INFPreIPOToken wToken)
    {
        // Decimals are fixed to 18
        uint256 amount = shares * 10 ** 18;
        address token = tokens[symbol];
        if (token == address(0)) {
            // New creation of token
            wToken = new INFPreIPOToken(msg.sender, name, symbol, amount, address(permissionManager));
            tokens[symbol] = address(wToken);
            tokenSymbols.push(symbol);
        } else {
            // Minting new shares
            wToken = INFPreIPOToken(token);
            wToken.mint(msg.sender, amount);
        }
    }

    function createMarket(
        IERC20 _token,
        uint256 _tokenSupply,
        address _paymentCurrency,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _goal,
        address _wallet
    )
        external onlyRole(ISSUER_ROLE) returns (address newMarket)
    {
        bytes memory data = abi.encode(address(this), address(_token), _paymentCurrency, _tokenSupply, _startTime, _endTime, _rate, _goal, msg.sender, pointListAdapter, _wallet);
        
        newMarket = bentoBox.deploy(marketTemplate, data, true);
        auctions[_token].push(newMarket);
        emit MarketCreated(msg.sender, newMarket, marketTemplate);

        _token.safeTransferFrom(msg.sender, address(this), _tokenSupply);
        _token.safeApprove(newMarket, _tokenSupply);
        IERC20(_paymentCurrency).safeApprove(newMarket, type(uint256).max);

        IMisoMarket(newMarket).initMarket(data);
       
        return newMarket;
    }

    /// @notice Allows msg.sender to commit funds to a given auction and whitelist themselves for the INF platform. 
    /// @param market The address of the market the user wants to participate in.
    /// @param amount The amount of approved ERC20 token.
    /// @param readAndAgreedToMarketParticipationAgreement Whether the user agreed to the market participation agreement.
    /// @param operator The address of the operator that approves or revokes access.
    /// @param deadline Time when signature expires to prohibit replays.
    /// @param v Part of the signature. (See EIP-191)
    /// @param r Part of the signature. (See EIP-191)
    /// @param s Part of the signature. (See EIP-191)
    function commitTokensAndWhitelist(
        IMisoMarket market,
        uint256 amount,
        bool readAndAgreedToMarketParticipationAgreement,
        address operator,
        uint256 deadline,
        uint256 deadline2,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint8 vPermit,
        bytes32 rPermit,
        bytes32 sPermit
    ) public {
        // If a signature is provided, the user is whitelisted
        if (r != 0 || s != 0 || v != 0) {
            permissionManager.setInvestorWhitelisting(operator, msg.sender, true, deadline, v, r, s);
        }

        IERC20 paymentToken = IERC20(market.paymentCurrency());

        if (rPermit != 0 || sPermit != 0 || vPermit != 0) {
            IPermit(address(paymentToken)).permit(msg.sender, address(this), type(uint256).max, deadline2, vPermit, rPermit, sPermit);
        }

        paymentToken.safeTransferFrom(msg.sender, address(this), amount);
        
        // Commit tokens to market.
        market.commitTokensFrom(msg.sender, amount, readAndAgreedToMarketParticipationAgreement);

        uint256 remainingBalance = paymentToken.balanceOf(address(this));
        if (remainingBalance > 0) {
            paymentToken.safeTransfer(msg.sender, remainingBalance);
        }
    }

    /// @notice Allows msg.sender to commit eth to a given auction and whitelist themselves for the INF platform. 
    /// @param market The address of the market the user wants to participate in.
    /// @param amount The amount of approved ERC20 token.
    /// @param readAndAgreedToMarketParticipationAgreement Whether the user agreed to the market participation agreement.
    /// @param operator The address of the operator that approves or revokes access.
    /// @param deadline Time when signature expires to prohibit replays.
    /// @param v Part of the signature. (See EIP-191)
    /// @param r Part of the signature. (See EIP-191)
    /// @param s Part of the signature. (See EIP-191)
    function commitTokensAndWhitelistETH (
        IMisoMarket market,
        uint256 amount,
        bool readAndAgreedToMarketParticipationAgreement,
        address operator,
        uint256 deadline,
        ISwapRouter.ExactOutputSingleParams memory params,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        SWAP_ROUTER.exactOutputSingle{value: msg.value}(params);
        // If a signature is provided, the user is whitelisted
        if (r != 0 || s != 0 || v != 0) {
            permissionManager.setInvestorWhitelisting(operator, msg.sender, true, deadline, v, r, s);
        }
        IERC20 paymentToken = IERC20(market.paymentCurrency());
        
        // Commit tokens to market.
        market.commitTokensFrom(msg.sender, amount, readAndAgreedToMarketParticipationAgreement);

        uint256 remainingBalance = paymentToken.balanceOf(address(this));
        if (remainingBalance > 0) {
            paymentToken.safeTransfer(msg.sender, remainingBalance);
        }

        if(address(this).balance > 0) {
            msg.sender.call{value: address(this).balance}("");
        }
    }

    function allTokenSymbols() public view returns (string[] memory) {
        return tokenSymbols;
    }

    function getAuctions(IERC20 token) public view returns (address[] memory) {
        return auctions[token];
    }

    receive() external payable {}
}