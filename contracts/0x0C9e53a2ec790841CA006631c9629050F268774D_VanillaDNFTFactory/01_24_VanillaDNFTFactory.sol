pragma solidity ^0.8.0;

import "@spanning/contracts/SpanningUtils.sol";
import "./NoDelegateCall.sol";
import "./interfaces/IVanillaDNFTDeployer.sol";
import "./VanillaDerivativeNFT.sol";

contract VanillaDNFTFactory is NoDelegateCall {
    // This allows us to efficiently unpack data in our address specification.
    using SpanningAddress for bytes32;

    struct SoftStakeNFTInfo {
        address originalContractAddress;
        uint256 tokenId;
        address derivativeContractAddress;
    }
    event BurnAll(address indexed caller);

    event NewVDNFT(address dnft);
    event DNFTdeployerUpdated(
        address indexed updater,
        address indexed newDeployerAddress
    );
    event SpanningLabDelegateUpdated(
        address indexed updater,
        address indexed newDelegateAddress
    );

    mapping(address => mapping(uint256 => address)) public getContractAddress; // original NFT address => tokenID => address
    mapping(address => SoftStakeNFTInfo) public getSoftStakedTokenInfo;
    SoftStakeNFTInfo[] public originalNFTInfoArray;
    address[] public deployedLicenseSC;
    address public DNFTDeployerAddress;
    address public DNFTDeployerUpdater;
    address public SpanningLabDelegate;

    constructor(address SpanningLabDelegate_) {
        DNFTDeployerUpdater = msg.sender;
        SpanningLabDelegate = SpanningLabDelegate_;
    }

    function setNewDeployerUpdater(address newDeployerUpdater) public {
        require(
            msg.sender == DNFTDeployerUpdater,
            "Only the assigned updater can update DNFT Deployer."
        );
        DNFTDeployerUpdater = newDeployerUpdater;
    }

    function setDNFTDeployerAddress(address newDNFTDeployer) public {
        require(
            msg.sender == DNFTDeployerUpdater,
            "Only the assigned updater can update DNFT Deployer."
        );
        DNFTDeployerAddress = newDNFTDeployer;
        emit DNFTdeployerUpdated(msg.sender, newDNFTDeployer);
    }

    function setNewSpanningLabDelegateAddress(address newDelegateAddress) public {
        require(
            msg.sender == DNFTDeployerUpdater,
            "Only the assigned updater can update DNFT spanning lab delegate address."
        );
        SpanningLabDelegate = newDelegateAddress;
        emit SpanningLabDelegateUpdated(msg.sender, newDelegateAddress);
    }

    function createDerivativeContract(
        address tokenAddress,
        uint256 tokenId
    ) public noDelegateCall returns (address contractAddress) {
        require(tokenAddress != address(0));
        require(
            getContractAddress[tokenAddress][tokenId] == address(0),
            "already exist"
        );
        contractAddress = IVanillaDNFTDeployer(DNFTDeployerAddress).deploy(
            address(this),
            tokenAddress,
            tokenId,
            SpanningLabDelegate
        );
        getContractAddress[tokenAddress][tokenId] = contractAddress;
        deployedLicenseSC.push(contractAddress);
        getSoftStakedTokenInfo[contractAddress] = SoftStakeNFTInfo(
            tokenAddress,
            tokenId,
            contractAddress
        );
        originalNFTInfoArray.push(
            SoftStakeNFTInfo(tokenAddress, tokenId, contractAddress)
        );
        emit NewVDNFT(contractAddress);
    }

    function getOriginalNFTInfo()
        public
        view
        returns (SoftStakeNFTInfo[] memory)
    {
        return originalNFTInfoArray;
    }

    function getDeployedLicenseAddress()
        public
        view
        returns (address[] memory)
    {
        return deployedLicenseSC;
    }

    // Get all minted licenses across all derivative contracts that commercialized by sender.
    function getAllMintedLicenses(
        address originalNftOwner
    ) public view returns (VanillaDerivativeNFT.TokenInfo[] memory) {
        uint256 totalCount;
        for (uint i = 0; i < deployedLicenseSC.length; i++) {
            VanillaDerivativeNFT derivativeContract = VanillaDerivativeNFT(
                deployedLicenseSC[i]
            );
            if (
                derivativeContract.getContractOwner() != bytes32(0) &&
                originalNftOwner == derivativeContract.getContractOwner().getAddress()
            ) {
                totalCount += derivativeContract.getCounterValue();
            }
        }
        VanillaDerivativeNFT.TokenInfo[]
            memory result = new VanillaDerivativeNFT.TokenInfo[](totalCount);
        uint256 currentCount;
        for (uint i = 0; i < deployedLicenseSC.length; i++) {
            VanillaDerivativeNFT derivativeContract = VanillaDerivativeNFT(
                deployedLicenseSC[i]
            );
            if (
                derivativeContract.getContractOwner() != bytes32(0) &&
                originalNftOwner == derivativeContract.getContractOwner().getAddress()
            ) {
                VanillaDerivativeNFT.TokenInfo[]
                    memory tokenInfos = derivativeContract.getTokenInfoList();
                for (uint j = 0; j < tokenInfos.length; j++) {
                    VanillaDerivativeNFT.TokenInfo
                        memory tokenInfoItem = tokenInfos[j];
                    result[currentCount] = tokenInfoItem;
                    currentCount++;
                }
            }
        }
        return result;
    }
}