// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IBridgeToken {
    function mint(address to, uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;
}

struct Network {
    string name;
    uint256 chainId;
}

struct Token {
    string stringAddress;
    Network network;
}

struct Request {
    address tokenAddress;
    address fromAccount;
    string network;
    uint256 toChainId;
    string targetAddress;
    uint256 amount;
    string toAccount;
}

struct User {
    uint256 totalReqCount;
    bytes32[] requests;
}

contract HexToysBridgeV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    address public constant NullAddress =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint public constant FEE_DIVIDER = 10000;
    uint public fee = 20; // 0.2%
    mapping(address => uint) public totalFee;

    bool public inChainConvert;
    address public feeAddress;
    address public signer;

    
    
    mapping(bytes32 => Request) public requestMap;
    bytes32[] public requests;

    mapping(string => bool) public claimHashs;

    // address(tokenAddress in this network) => network => chainId => string(tokenAddress target)
    mapping(address => mapping(string => mapping(uint256 => string)))
        public tokenMap;

    mapping(string => mapping(uint256 => bool)) public isValidNetwork;
    mapping(string => mapping(uint256 => uint256)) public networkIndex;

    mapping(address => User) public users;

    Network[] public networks;

    string[] public claims;

    address public blackHold;

    mapping(address => bool) public isMintBurn;

    event Convert(
        address indexed tokenAddress,
        address indexed fromAccount,
        string network,
        uint256 toChainId,
        string targetAddress,
        uint256 amount,
        string toAccount,
        bytes32 hash
    );

    event Claim(string convertHash);

    modifier onlyValidNetwork(string memory network, uint256 chainId) {
        require(isValidNetwork[network][chainId], "Bridge: Invalid Network");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _feeAddress,
        address _signer
    ) external initializer {
        feeAddress = _feeAddress;
        signer = _signer;
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setInChainConvert(bool enabled) external onlyOwner {
        inChainConvert = enabled;
    }

    function addNetwork(
        string memory network,
        uint256 chainId
    ) external onlyOwner {
        require(
            isValidNetwork[network][chainId] == false,
            "Bridge: Network Already Added"
        );
        isValidNetwork[network][chainId] = true;
        networkIndex[network][chainId] = networks.length;
        networks.push(Network({name: network, chainId: chainId}));
    }

    function networkLength() public view returns (uint256) {
        return networks.length;
    }

    function removeNetwork(
        string memory network,
        uint256 chainId
    ) external onlyOwner onlyValidNetwork(network, chainId) {
        uint256 index = networkIndex[network][chainId];
        uint256 i;
        for (i = index; i < networks.length - 1; i++) {
            networks[i] = networks[i + 1];
        }
        networks.pop();
    }

    function setToken(
        string memory network,
        string memory stringAddress,
        address tokenAddress,
        uint256 chainId
    ) external onlyOwner onlyValidNetwork(network, chainId) {
        tokenMap[tokenAddress][network][chainId] = stringAddress;
    }

    function setFee(uint _fee) external onlyOwner {
        fee = _fee;
    }

    function setTokenMintable(
        address tokenAddress,
        bool isMintable
    ) external onlyOwner {
        isMintBurn[tokenAddress] = isMintable;
    }

    function setFeeAddress(address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
    }

    function convert(
        address tokenAddress,
        string memory toAccount,
        string memory network,
        uint256 chainId,
        uint256 amount
    ) external payable onlyValidNetwork(network, chainId) {
        if (!inChainConvert) {
            require(chainId != block.chainid, "Bridge: Invalid ChainId");
        }
        if (NullAddress == tokenAddress) {
            require(msg.value == amount, "Bridge: Invalid Pay Amount");
        } else {
            if (isMintBurn[tokenAddress]) {
                IBridgeToken(tokenAddress).burnFrom(msg.sender, amount);
            } else if (blackHold != address(0)) {
                IERC20(tokenAddress).safeTransferFrom(
                    msg.sender,
                    blackHold,
                    amount
                );
            } else {
                IERC20(tokenAddress).safeTransferFrom(
                    msg.sender,
                    address(this),
                    amount
                );
            }
        }
        string memory targetAddress = tokenMap[tokenAddress][network][chainId];
        require(bytes(targetAddress).length > 0, "Bridge: Token Not Definded");

        bytes32 hash = keccak256(
            abi.encodePacked(
                requests.length,
                tokenAddress,
                msg.sender,
                block.chainid,
                network,
                chainId,
                targetAddress,
                amount,
                toAccount
            )
        );

        requests.push(hash);
        Request memory req = Request({
            tokenAddress: tokenAddress,
            fromAccount: msg.sender,
            network: network,
            toChainId: chainId,
            targetAddress: targetAddress,
            amount: amount,
            toAccount: toAccount
        });

        requestMap[hash] = req;

        users[msg.sender].totalReqCount += 1;
        users[msg.sender].requests.push(hash);

        emit Convert(
            tokenAddress,
            msg.sender,
            network,
            chainId,
            targetAddress,
            amount,
            toAccount,
            hash
        );
    }

    function getUserRequests(
        address userAddress
    ) external view returns (bytes32[] memory) {
        return users[userAddress].requests;
    }

    function getUserReqCount(
        address userAddress
    ) external view returns (uint256) {
        return users[userAddress].totalReqCount;
    }

    function getTotalRequests() external view returns (bytes32[] memory) {
        return requests;
    }

    function getTotalReqCount() external view returns (uint256) {
        return requests.length;
    }

    function claim(
        address tokenAddress,
        address toAccount,
        string memory network,
        uint256 chainId,
        uint256 amount,
        string memory convertHash,
        bytes calldata signature
    ) external onlyValidNetwork(network, chainId) {
        require(claimHashs[convertHash] != true, "Already spent");
        bytes32 hash = keccak256(
            abi.encodePacked(
                address(this),
                toAccount,
                tokenAddress,
                block.chainid,
                network,
                chainId,
                amount,
                convertHash
            )
        );
        require(
            hash.toEthSignedMessageHash().recover(signature) == signer,
            "BRIDGE: invalid signature"
        );

        claimHashs[convertHash] = true;
        claims.push(convertHash);

        uint feeAmount;
        if(feeAddress != address(0)) {
            feeAmount = amount * fee / FEE_DIVIDER;
            totalFee[tokenAddress] += feeAmount;
            amount -= amount;
        }

        if (tokenAddress == NullAddress) {
            Address.sendValue(payable(toAccount), amount);
        } else if (isMintBurn[tokenAddress]) {
            IBridgeToken(tokenAddress).mint(toAccount, amount);
        } else {
            IERC20(tokenAddress).safeTransfer(toAccount, amount);
        }
        emit Claim(convertHash);
    }

    function collectFees(address tokenAddress) external onlyOwner {
        if (tokenAddress == NullAddress) {
            Address.sendValue(payable(feeAddress), totalFee[tokenAddress]);
        } else if (isMintBurn[tokenAddress]) {
            IBridgeToken(tokenAddress).mint(feeAddress, totalFee[tokenAddress]);
        } else {
            IERC20(tokenAddress).safeTransfer(feeAddress, totalFee[tokenAddress]);
        }
    }



    function getClaims() external view returns (string[] memory) {
        return claims;
    }

    function getClaimCount() external view returns (uint256) {
        return claims.length;
    }

    function setBlockHold(address _black) external onlyOwner {
        blackHold = _black;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    receive() external payable {}
}