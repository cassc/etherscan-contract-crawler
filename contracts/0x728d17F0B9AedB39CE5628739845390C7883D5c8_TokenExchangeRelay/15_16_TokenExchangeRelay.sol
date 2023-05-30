// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Utils.sol";

/** @title Tokens exchange relay. */
contract TokenExchangeRelay is AccessControl {
    using Address for address;
    using SafeERC20 for IERC20;
    using StringHelper for bytes;
    using SafeMath for uint256;

    address payable public zerox;
    address payable public WETH;
    bytes32 public constant FORWARDER_ROLE = keccak256("FORWARDER_ROLE");

    constructor(address payable _zerox, address payable _weth) {
        require(
            _zerox == 0xDef1C0ded9bec7F1a1670819833240f027b25EfF ||
                _zerox == 0xF91bB752490473B8342a3E964E855b9f9a2A668e ||
                _zerox == 0xF471D32cb40837bf24529FCF17418fC1a4807626 ||
                _zerox == 0xDEF189DeAEF76E379df891899eb5A00a94cBC250 ||
                _zerox == 0xDEF1ABE32c034e558Cdd535791643C58a13aCC10,
            "TER0"
        );
        require(
            _weth == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 || _weth == 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6,
            "TER1"
        );
        zerox = _zerox;
        WETH = _weth;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(FORWARDER_ROLE, msg.sender);
    }

    /** @dev Token exchange
     * @param tokenSell address of the ERC20 token to sell
     * @param tokenBuy address of the ERC20 token to buy
     * @param tokenSellAmount amount of the ERC20 token to sell (incudes net fees)
     * @param tokenFee fee in amount of the ERC20 sell token
     * @param from sender address
     * @param swapTarget allowanceTarget from the 0x API call response
     * @param approveData approveData
     * @param swapCallDataForEthBribe `data` field from the 0x API response for swaping token to ETH.
     * @param swapCallDataForExchange `data` field from the 0x API response for swaping sell token to buy token.
     * @param minerFee fee amount in eth to pay to block.coinbase (optional, can be zero)
     * @param sig digest signature from address (from)
     * @param deadline  the unix time in a future that you can specify to avoid the case of execution after that deadline
     */
    struct ExchangeInfo {
        IERC20 tokenSell;
        IERC20 tokenBuy;
        uint256 tokenSellAmount;
        uint256 tokenFee;
        address from;
        address swapTarget;
        bytes approveData;
        bytes swapCallDataForEthBribe;
        bytes swapCallDataForExchange;
        uint256 minerFee;
        bytes sig;
        uint256 deadline;
    }
    //to avoid replay
    mapping(address => uint256) public nonce;

    event Exchanged(
        address indexed signer,
        address indexed tokenSell,
        address indexed tokenBuy,
        uint256 tokenSellAmount,
        uint256 tokenBuyAmount,
        uint256 tokenFee,
        uint256 minerfee,
        uint256 fee,
        bytes32 _hash
    );

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "TER: EXPIRED");
        _;
    }

    function getHash(ExchangeInfo memory info) public view returns (bytes32 retval) {
        retval = keccak256(
            abi.encodePacked(
                address(this),
                info.from,
                info.approveData,
                info.swapCallDataForEthBribe,
                info.swapCallDataForExchange,
                address(info.tokenSell),
                address(info.tokenBuy),
                info.tokenSellAmount,
                info.tokenFee,
                info.deadline,
                nonce[info.from]
            )
        );
    }

    // borrowed from OpenZeppelin's ESDA stuff:
    // https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/cryptography/ECDSA.sol
    function _verifySignature(address signer, bytes32 _hash, bytes memory signature) internal pure returns (bool) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        // Check the signature length
        if (signature.length != 65) {
            return false;
        }
        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return false;
        } else {
            address recoveredAddress = ecrecover(
                keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)),
                v,
                r,
                s
            );
            return recoveredAddress == signer;
        }
    }

    function setupForwarders(address[] memory accounts) public onlyRole(getRoleAdmin(FORWARDER_ROLE)) {
        for (uint256 i = 0; i < accounts.length; i++) {
            _grantRole(FORWARDER_ROLE, accounts[i]);
        }
    }

    /** @dev Perform tokens exchange and takes fee exchanged token (eth)
     * @param info see ExchangeInfo struct
     */
    function exchange(ExchangeInfo memory info) external payable ensure(info.deadline) {
        require(hasRole(FORWARDER_ROLE, msg.sender), "TER01");
        require(address(info.tokenSell) != address(0), "TER02");
        require(address(info.tokenBuy) != address(0), "TER03");
        require(info.tokenSellAmount > 0, "TER04");
        require(info.tokenFee > 0, "TER05");
        require(info.from != address(0), "TER06");
        require(info.swapCallDataForEthBribe.length > 0, "TER07");
        require(info.swapCallDataForExchange.length > 0, "TER08");
        uint256 totalTokens = info.tokenSellAmount.add(info.tokenFee);
        require(info.tokenSell.allowance(info.from, address(this)) >= totalTokens, "TER09");
        require(info.approveData.length > 0, "TER10");
        require(info.sig.length > 0, "TER11");

        //the hash contains all of the information about the meta transaction to be called
        bytes32 _hash = getHash(info);

        require(_verifySignature(info.from, _hash, info.sig), "TER911");

        nonce[info.from]++;

        info.tokenSell.safeTransferFrom(info.from, address(this), totalTokens);

        if (info.swapTarget != address(0) && info.tokenSell.allowance(address(this), info.swapTarget) < totalTokens) {
            // reset to zero since some token like USDT require it before setting allowance
            _callOptionalReturn(
                info.tokenSell,
                abi.encodeWithSelector(info.tokenSell.approve.selector, info.swapTarget, 0)
            );
            // set max allowance
            _callOptionalReturn(
                info.tokenSell,
                abi.encodeWithSelector(info.tokenSell.approve.selector, info.swapTarget, type(uint256).max)
            );
        }

        address callTarget = zerox;
        if (address(info.tokenSell) == WETH) {
            callTarget = WETH;
        }

        (bool success, bytes memory res) = callTarget.call(info.swapCallDataForEthBribe);

        require(success, string(bytes("TER12: ").concat(bytes(res.getRevertMsg()))));

        if (info.minerFee > 0) {
            block.coinbase.transfer(info.minerFee);
        }

        // send current eth balance to the tx sender(owner)
        uint256 fee = address(this).balance;
        if (fee > 0) {
            (success, ) = payable(msg.sender).call{value: fee}("");
            require(success, "TER13");
        }

        require(info.tokenSell.balanceOf(address(this)) >= info.tokenSellAmount, "TER14");

        callTarget = zerox;
        if (address(info.tokenSell) == WETH && address(info.tokenBuy) == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            callTarget = WETH;
        }
        (success, res) = callTarget.call{value: msg.value}(info.swapCallDataForExchange);

        require(success, string(bytes("TER15: ").concat(bytes(res.getRevertMsg()))));

        uint256 tokenBuyAmount;
        if (address(info.tokenBuy) == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            tokenBuyAmount = address(this).balance;
            if (tokenBuyAmount > 0) {
                (success, ) = payable(info.from).call{value: tokenBuyAmount}("");
                require(success, "TER16");
            }
        }
        else {
            tokenBuyAmount = info.tokenBuy.balanceOf(address(this));
            require(tokenBuyAmount > 0, "TER17");
            info.tokenBuy.safeTransfer(info.from, tokenBuyAmount);
        }

        // send all balances to the tx sender(owner)
        {
            uint256 balance = address(this).balance;
            if (balance > 0) {
                (success, ) = payable(msg.sender).call{value: balance}("");
                require(success, "TER18");
            }

            info.tokenSell.safeTransfer(msg.sender, info.tokenSell.balanceOf(address(this)));
        }
        ///

        emit Exchanged(
            info.from,
            address(info.tokenSell),
            address(info.tokenBuy),
            info.tokenSellAmount,
            tokenBuyAmount,
            info.tokenFee,
            info.minerFee,
            fee,
            _hash
        );
    }

    function topup(address to, uint256 deadline) external payable ensure(deadline) {
        require(hasRole(FORWARDER_ROLE, msg.sender), "TER01");
        require(to != address(0), "TER111");
        require(!to.isContract(), "TER112");
        Address.sendValue(payable(to), msg.value);
    }

    receive() external payable {}

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}