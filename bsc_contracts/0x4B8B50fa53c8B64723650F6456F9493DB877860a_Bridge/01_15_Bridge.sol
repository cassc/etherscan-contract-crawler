// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity =0.8.4;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

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

contract Bridge is UUPSUpgradeable, Ownable, Initializable {
    using ECDSA for bytes32;

    address public constant NullAddress =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    bool public started;
    bool public inChainConvert;
    address public feeAddress;
    address public signer;

    mapping(bytes32 => Request) public requestMap;
    bytes32[] public requests;

    mapping(string => bool) public claimHashs;

    // network => chainId => address(tokenAddress in this network) => string(tokenAddress target)
    mapping(address => mapping(string => mapping(uint256 => string)))
        public tokenMap;

    mapping(string => mapping(uint256 => bool)) public isValidNetwork;
    mapping(string => mapping(uint256 => uint256)) public networkIndex;

    mapping(address => User) public users;

    Network[] public networks;

    string[] public claims;

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

    function initialize(address _feeAddress, address _signer)
        external
        initializer
    {
        started = false;
        feeAddress = _feeAddress;
        signer = _signer;
        _transferOwnership(tx.origin);
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setInChainConvert(bool enabled) external onlyOwner {
        inChainConvert = enabled;
    }

    function addNetwork(string memory network, uint256 chainId)
        external
        onlyOwner
    {
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

    function removeNetwork(string memory network, uint256 chainId)
        external
        onlyOwner
        onlyValidNetwork(network, chainId)
    {
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
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            );
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

    function getUserRequests(address userAddress)
        external
        view
        returns (bytes32[] memory)
    {
        return users[userAddress].requests;
    }

    function getUserReqCount(address userAddress)
        external
        view
        returns (uint256)
    {
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

        if (tokenAddress == NullAddress) {
            Address.sendValue(payable(toAccount), amount);
        } else {
            IERC20(tokenAddress).transfer(toAccount, amount);
        }
        emit Claim(convertHash);
    }

    function getClaims() external view returns (string[] memory) {
        return claims;
    }

    function getClaimCount() external view returns (uint256) {
        return claims.length;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    receive() external payable {}
}