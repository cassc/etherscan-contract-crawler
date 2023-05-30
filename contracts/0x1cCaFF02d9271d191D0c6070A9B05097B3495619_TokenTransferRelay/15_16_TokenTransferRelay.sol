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

/** @title Tokens transfer relay. */
contract TokenTransferRelay is AccessControl {
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
            "TTR0"
        );
        require(
            _weth == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 || _weth == 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6,
            "TTR1"
        );
        zerox = _zerox;
        WETH = _weth;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(FORWARDER_ROLE, msg.sender);
    }

    /** @dev Token transfer
     * @param token address of the ERC20 token
     * @param tokenAmount amount of the ERC20 token
     * @param tokenFee fee in amount of the ERC20 token
     * @param from sender address
     * @param recipient recipient of the ERC20 token
     * @param swapTarget allowanceTarget from the 0x API call response
     * @param swapCallDataForEthBribe `data` field from the 0x API response for swaping token to ETH. Note: The takerAddress must be this contract for 0x API quote call.
     * @param minerFee fee amount in eth to pay to block.coinbase (optional, can be zero)
     * @param sig digest signature from address (from)
     * @param deadline  the unix time in a future that you can specify to avoid the case of execution after that deadline
     */
    struct ForwardInfo {
        IERC20 token;
        uint256 tokenAmount;
        uint256 tokenFee;
        address from;
        address recipient;
        address swapTarget;
        bytes approveData;
        bytes swapCallDataForEthBribe;
        uint256 minerFee;
        bytes sig;
        uint256 deadline;
    }
    //to avoid replay
    mapping(address => uint256) public nonce;

    event Forwarded(
        bytes sig,
        address indexed signer,
        address indexed destination,
        bytes data,
        address indexed token,
        uint256 tokenAmount,
        uint256 tokenFee,
        uint256 minerfee,
        uint256 fee,
        bytes32 _hash
    );

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "TTR: EXPIRED");
        _;
    }

    function getHash(ForwardInfo memory info) public view returns (bytes32 retval) {
        retval = keccak256(
            abi.encodePacked(
                address(this),
                info.from,
                info.recipient,
                info.approveData,
                info.swapCallDataForEthBribe,
                address(info.token),
                info.tokenAmount,
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

    /** @dev Perform tokens transfer to required recipient and pay to miner with exchanged token
     * @param info see ForwardInfo struct
     */
    function forward(ForwardInfo memory info) external ensure(info.deadline) {
        require(hasRole(FORWARDER_ROLE, msg.sender), "TTR01");
        require(address(info.token) != address(0), "TTR10");
        require(info.tokenAmount > 0, "TTR20");
        require(info.tokenFee > 0, "TTR21");
        require(info.from != address(0), "TTR30");
        require(info.recipient != address(0), "TTR40");
        require(info.swapCallDataForEthBribe.length > 0, "TTR70");

        uint256 totalTokens = info.tokenAmount.add(info.tokenFee);
        require(info.token.allowance(info.from, address(this)) >= totalTokens, "TTR80");
        require(info.approveData.length > 0, "TTR110");
        require(info.sig.length > 0, "TTR120");

        //the hash contains all of the information about the meta transaction to be called
        bytes32 _hash = getHash(info);

        require(_verifySignature(info.from, _hash, info.sig), "TTR911");

        nonce[info.from]++;

        info.token.safeTransferFrom(info.from, address(this), totalTokens);

        if (info.swapTarget != address(0) && info.token.allowance(address(this), info.swapTarget) < totalTokens) {
            // reset to zero since some token like USDT require it before setting allowance
            _callOptionalReturn(info.token, abi.encodeWithSelector(info.token.approve.selector, info.swapTarget, 0));
            // set max allowance
            _callOptionalReturn(
                info.token,
                abi.encodeWithSelector(info.token.approve.selector, info.swapTarget, type(uint256).max)
            );
        }
        address callTarget = zerox;
        if (address(info.token) == WETH) {
            callTarget = WETH;
        }
        
        (bool success, bytes memory res) = callTarget.call(info.swapCallDataForEthBribe);
        require(success, string(bytes("TTR90: ").concat(bytes(res.getRevertMsg()))));

        require(info.token.balanceOf(address(this)) >= info.tokenAmount, "TTR100");
        info.token.safeTransfer(info.recipient, info.tokenAmount);
        if (info.minerFee > 0) {
            block.coinbase.transfer(info.minerFee);
        }
        // send all balances to the tx sender(owner)
        uint256 fee = address(this).balance;
        if (fee > 0) {
            (success, ) = payable(msg.sender).call{value: fee}("");
            require(success, "TTR800");
        }
        info.token.safeTransfer(msg.sender, info.token.balanceOf(address(this)));
        emit Forwarded(
            info.sig,
            info.from,
            info.recipient,
            info.approveData,
            address(info.token),
            info.tokenAmount,
            info.tokenFee,
            info.minerFee,
            fee,
            _hash
        );
    }

    function topup(address to, uint256 deadline) external payable ensure(deadline) {
        require(hasRole(FORWARDER_ROLE, msg.sender), "TTR01");
        require(to != address(0), "TTR111");
        require(!to.isContract(), "TTR112");
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