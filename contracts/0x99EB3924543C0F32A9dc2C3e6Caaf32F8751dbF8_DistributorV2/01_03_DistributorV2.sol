// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract DistributorV2 {
    address public IVY_BOYS_ADDRESS =
        0x809D8f2B12454FC07408d2479cf6DC701ecD5a9f;
    address public SERUM_ADDRESS = 0x59BDB74d66bDdBF32f632B6bD9B3a2b35477D7A5;
    address public owner;
    address public UPGRADED_PET_ADDRESS;
    bool public isUpgradingActive;
    mapping(uint256 => bool)[3] public superUpgrades;
    mapping(uint256 => bool)[3] public megaUpgrades;

    constructor() {
        owner = msg.sender;
    }

    address[3] public petContracts = [
        0xf4f5fbF9ecc85F457aA4468F20Fa88169970c44D,
        0x51061aA713BF11889Ea01183633ABb3c2f62cADF,
        0xd6F047bC6E5c0e39E4Ca97E6706221D4C47D1D56
    ];

    function upgradePets(uint256[][3] calldata _tokenIds, uint8 _serumCount)
        external
    {
        require(isUpgradingActive, "Upgrading not active");
        require(
            IIvyBoys(IVY_BOYS_ADDRESS).balanceOf(msg.sender) > 0,
            "Need at least one ivy boy"
        );
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            for (uint256 j; j < _tokenIds[i].length; j++) {
                uint256 selectedTokenId = _tokenIds[i][j];
                if (_serumCount == 1) {
                    require(
                        !superUpgrades[i][selectedTokenId],
                        "Token already upgraded"
                    );
                    superUpgrades[i][selectedTokenId] = true;
                }
                if (_serumCount == 5) {
                    require(
                        !megaUpgrades[i][selectedTokenId],
                        "Token already upgraded"
                    );
                    megaUpgrades[i][selectedTokenId] = true;
                }
            }
            IIvyPet(petContracts[i]).upgrade(_tokenIds[i], _serumCount);
        }
        uint256 mintCount = _tokenIds[0].length +
            _tokenIds[1].length +
            _tokenIds[2].length;
        ISerum(SERUM_ADDRESS).burnExternal(_serumCount * mintCount, msg.sender);
        IUpgradedPets(UPGRADED_PET_ADDRESS).mint(
            _tokenIds,
            msg.sender,
            _serumCount
        );
    }

    // ==== SETTERS ====

    function setPetContracts(
        address _dog,
        address _cat,
        address _bear
    ) external onlyOwner {
        petContracts = [_dog, _cat, _bear];
    }

    function setUpgradedPets(address _address) external onlyOwner {
        UPGRADED_PET_ADDRESS = _address;
    }

    function setIvyBoysContract(address _address) external onlyOwner {
        IVY_BOYS_ADDRESS = _address;
    }

    function setSerum(address _address) public onlyOwner {
        SERUM_ADDRESS = _address;
    }

    function setSwitches(bool _upgrade) public onlyOwner {
        isUpgradingActive = _upgrade;
    }

    // ==== UTIL ====

    function getPetTokens(address _address)
        public
        view
        returns (uint256[][3] memory)
    {
        uint256[][3] memory output;
        for (uint256 i = 0; i < 3; i++) {
            output[i] = IIvyPet(petContracts[i]).tokensOfOwner(_address);
        }
        return output;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Can only be called by owner");
        _;
    }
}

interface IIvyPet {
    function mint(uint256 _quantity, address _minter) external;

    function upgrade(uint256[] calldata _tokenIds, uint8 _serumCount) external;

    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory);
}

interface IIvyBoys {
    function ownerOf(uint256 token_id) external returns (address);

    function balanceOf(address _owner) external view returns (uint256);
}

interface ISerum {
    function burnExternal(uint256 _amount, address _caller) external;
}

interface IUpgradedPets {
    function mint(
        uint256[][3] calldata _tokenIds,
        address _minter,
        uint256 _serumCount
    ) external;
}