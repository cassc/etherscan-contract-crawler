// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../factory/FactoryInterface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UserRedemption is Ownable {
    event UserBurn(address indexed who, uint256 indexed amount, uint256 indexed nonce);

    struct Req {
        uint256 amount;
        address requester;
        string ipfsHash;
    }

    FactoryInterface public immutable factory;
    IERC20 public immutable token;

    address public signer;
    address public feeReceiver;

    uint256 public feeBPS;
    uint256 public feeFlat;
    uint256 public feesCollected;

    mapping(address => uint256) public user_req_nonce;

    Req[] public reqs;

    string public constant version = "0";
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)");
    bytes32 public constant WHITELIST_TYPEHASH = keccak256("Whitelist(address addr,uint256 amount,uint256 nonce)");

    modifier only(address who) {
        require(msg.sender == who, "incorrect permissions");
        _;
    }

    constructor(
        address _signer,
        address _factory,
        address _token,
        address _feeReceiver,
        uint256 _feeBPS,
        uint256 _feeFlat,
        address _owner
    ) {
        signer = _signer;
        factory = FactoryInterface(_factory);
        token = IERC20(_token);
        feeReceiver = _feeReceiver;
        feeBPS = _feeBPS;
        feeFlat = _feeFlat;
        _transferOwnership(_owner);
    }

    function burn(
        uint256 amount,
        string calldata _ipfsHash,
        bytes calldata signature
    ) external {
        uint256 fee = fee(amount);

        require(amount >= fee, "fee less than minimum");

        feesCollected += fee;

        bytes32 _hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        WHITELIST_TYPEHASH, 
                        msg.sender, 
                        amount, 
                        user_req_nonce[msg.sender]++
                ))
            )
        );

        require(signer == recoverSigner(_hash, signature), "invalid signer");

        reqs.push(Req({amount: amount - fee, requester: msg.sender, ipfsHash: _ipfsHash}));

        token.transferFrom(msg.sender, address(this), amount);

        emit UserBurn(msg.sender, amount, reqs.length - 1);
    }

    function batchBurn(uint256 amount) external onlyOwner {
        require(amount <= token.balanceOf(address(this)) - feesCollected, "invalid amount");
        token.approve(address(factory), amount);
        factory.burn(amount, "");
    }

    function takeFees() external only(feeReceiver) {
        token.transfer(feeReceiver, feesCollected);
        feesCollected = 0;
    }

    function changeSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function changeFeeReciever(address _receiver) external onlyOwner {
        feeReceiver = _receiver;
    }

    function changeFeeBPS(uint256 _fee) external onlyOwner {
        feeBPS = _fee;
    }

    function changeFeeFlat(uint256 _fee) external onlyOwner {
        feeFlat = _fee;
    }

    function setMerchantDepositAddress(string memory addr) external onlyOwner {
        factory.setMerchantDepositAddress(addr);
    }

    function removeFunds(uint256 amount) external onlyOwner {
        require(amount <= token.balanceOf(address(this)) - feesCollected, "invalid amount");
        token.transfer(msg.sender, amount);
    }

    //////////////////////// VIEW ////////////////////////

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    DOMAIN_TYPEHASH,
                    keccak256("User Redemption Contract"),
                    keccak256(bytes(version)),
                    block.chainid,
                    address(this),
                    0x146eb79745af938dd35c008f08e6a37823a1278b392df477f9849e461956c27a
                )
            );
    }

    // can never be less than feeFlat
    function fee(uint256 amount) public view returns (uint256) {
        return (amount * feeBPS / 10000) + feeFlat;
    }

    //////////////////////// INTERNAL ////////////////////////
        function recoverSigner(bytes32 messageHash, bytes memory _signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(_signature, 32))
            // second 32 bytes
            s := mload(add(_signature, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_signature, 96)))
        }

        return ecrecover(messageHash, v, r, s);
    }
}