// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./interfaces/IOrbsNFT.sol";

contract OrbsNFT is ERC721Enumerable, Ownable, VRFConsumerBase, IOrbsNFT {
    using SafeERC20 for IERC20;

    event MintRequested(
        address indexed requester,
        bytes32 requestId,
        uint256 amount
    );
    event MinterChanged(address indexed minter);
    event MinterRemoved(address indexed minter);
    event BaseUriUpgradeableFreezed();
    event BaseUriUpdated(string baseUri);
    event VrfConfigUpdated(bytes32 vrfKeyHash, uint256 vrfFee);

    struct MintRequest {
        address beneficiary;
        uint256 amount;
    }

    uint256 public constant MAX_SUPPLY = 3333;

    bytes32 public vrfKeyHash;
    uint256 public vrfFee;

    mapping(bytes32 => MintRequest) public mintRequests;
    uint256 public pending;
    address public minter;
    bool public canUpgradeBaseURI;
    string private _baseURI_;
    mapping(uint256 => uint256) private _randomForwarder;

    constructor(
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _vrfKeyhash,
        uint256 _vrfFee,
        bool _canUpgradeBaseURI
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) ERC721("The Orbs", "ORBS") {
        vrfKeyHash = _vrfKeyhash;
        vrfFee = _vrfFee;
        canUpgradeBaseURI = _canUpgradeBaseURI;
    }

    function freezeBaseUriUpgradeable() external onlyOwner {
        require(canUpgradeBaseURI, "OrbsNFT: already frozen");
        canUpgradeBaseURI = false;

        emit BaseUriUpgradeableFreezed();
    }

    function setBaseURI(string memory newBaseUri) external onlyOwner {
        require(canUpgradeBaseURI, "OrbsNFT: frozen");
        _baseURI_ = newBaseUri;

        emit BaseUriUpdated(newBaseUri);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURI_;
    }

    function requestMint(address beneficiary, uint256 amount)
        external
        override
        returns (bytes32)
    {
        require(minter == msg.sender, "OrbsNFT: caller is not the minter");
        require(amount > 0, "OrbsNFT: amount is zero");

        bytes32 requestId = requestRandomness(vrfKeyHash, vrfFee);
        require(
            mintRequests[requestId].beneficiary == address(0),
            "OrbsNFT: Has pending request"
        );
        pending += amount;
        require(
            MAX_SUPPLY - totalSupply() >= pending,
            "OrbsNFT: Not enough NFTs"
        );
        mintRequests[requestId] = MintRequest(beneficiary, amount);

        emit MintRequested(beneficiary, requestId, amount);
        return requestId;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
        internal
        override
    {
        MintRequest memory mintRequest = mintRequests[requestId];
        require(
            mintRequest.beneficiary != address(0),
            "OrbsNFT: Invalid request"
        );
        uint256 remainingNFTs = MAX_SUPPLY - totalSupply();
        uint256 amount = mintRequest.amount;

        require(remainingNFTs >= amount, "OrbsNFT: No enough NFTs");

        for (uint256 i = 0; i < amount; i += 1) {
            randomNumber = uint256(keccak256(abi.encode(randomNumber, i)));
            uint256 newId = (randomNumber % remainingNFTs) + 1;
            uint256 newTokenId = _randomForwarder[newId] > 0
                ? _randomForwarder[newId]
                : newId;
            _randomForwarder[newId] = _randomForwarder[remainingNFTs] > 0
                ? _randomForwarder[remainingNFTs]
                : remainingNFTs;

            _safeMint(mintRequest.beneficiary, newTokenId);

            remainingNFTs--;
        }

        pending -= amount;

        delete mintRequests[requestId];
    }

    function setMinter(address _minter) external onlyOwner {
        require(_minter != address(0), "OrbsNFT: minter is address(0)");
        minter = _minter;
        emit MinterChanged(_minter);
    }

    function setVrfConfig(bytes32 _vrfKeyHash, uint256 _vrfFee)
        external
        onlyOwner
    {
        vrfKeyHash = _vrfKeyHash;
        vrfFee = _vrfFee;
        emit VrfConfigUpdated(_vrfKeyHash, _vrfFee);
    }

    function recoverERC20(IERC20 _token, uint256 _amount) external onlyOwner {
        _token.safeTransfer(owner(), _amount);
    }
}