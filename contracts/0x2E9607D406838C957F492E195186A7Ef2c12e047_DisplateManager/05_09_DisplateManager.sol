// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./utils/CloneFactory.sol";
import "../interfaces/INFT.sol";
import "../interfaces/IAccessManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

contract DisplateManager is CloneFactory, Ownable {
    string public baseTokenUri;
    address accessManagerAddress;
    address public templateAddress;

    IAccessManager accessManager;

    event NFTDropped(address _NFTAddress, uint32 _nftId);

    modifier isOperationalAddress() {
        require(
            accessManager.isOperationalAddress(msg.sender) == true,
            "You are not allowed to use this function"
        );
        _;
    }

    constructor(
        address _accessManangerAddress,
        address _templateAddress,
        string memory _baseTokenUri
    ) {
        setAccessManagerAddress(_accessManangerAddress);
        accessManager = IAccessManager(accessManagerAddress);
        templateAddress = _templateAddress;
        baseTokenUri = _baseTokenUri;
    }

    function NFTDrop(bytes memory _data) external isOperationalAddress {
        uint32 staticDataLength = BytesLib.toUint32(
            BytesLib.slice(_data, 0, 4),
            0
        );

        bytes memory staticData = BytesLib.slice(
            _data,
            4,
            staticDataLength / 2
        );

        uint32 amountOfNFT = BytesLib.toUint32(
            BytesLib.slice(_data, staticDataLength / 2 + 3, 4),
            0
        );

        bytes memory dynamicDataForLoop = BytesLib.slice(
            _data,
            staticDataLength / 2 + 7,
            _data.length - (staticDataLength / 2 + 7)
        );

        uint32 singleNftLength;

        singleNftLength = BytesLib.toUint32(
            BytesLib.slice(_data, staticDataLength / 2 + 7, 4),
            0
        );

        uint32 position = 0;

        for (uint32 i = 0; i < amountOfNFT; i++) {
            bytes memory dynamicData = BytesLib.slice(
                dynamicDataForLoop,
                position + 4,
                singleNftLength
            );

            uint32 nftId = uint32(
                BytesLib.toUint256(BytesLib.slice(dynamicData, 32, 32), 0)
            );

            address clonedNFTAddress = createClone(templateAddress);
            INFT clonedNFT = INFT(clonedNFTAddress);

            clonedNFT.init(accessManagerAddress, staticData, dynamicData);

            emit NFTDropped(clonedNFTAddress, nftId);

            if (i + 1 < amountOfNFT) {
                uint32 oldLength = singleNftLength;

                singleNftLength = BytesLib.toUint32(
                    BytesLib.slice(
                        dynamicDataForLoop,
                        position + oldLength + 4,
                        4
                    ),
                    0
                );

                position += oldLength + 4;
            }
        }
    }

    function setAccessManagerAddress(address _newAccessManagerAddress)
        public
        onlyOwner
    {
        accessManagerAddress = _newAccessManagerAddress;
    }

    function setBaseTokenUri(string memory _newBaseTokenUri)
        public
        isOperationalAddress
    {
        baseTokenUri = _newBaseTokenUri;
    }

    function setTemplateAddress(address _newTemplateAddress)
        public
        isOperationalAddress
    {
        templateAddress = _newTemplateAddress;
    }
}