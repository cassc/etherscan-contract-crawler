// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum House {
    Scarred,
    Arms,
    Hearts,
    Sight,
    Hearing,
    Shadows
}

library HouseUtil {
    function toString(House _house) internal pure returns (string memory) {
        if (_house == House.Arms) {
            return "Arms";
        } else if (_house == House.Hearts) {
            return "Hearts";
        } else if (_house == House.Sight) {
            return "Sight";
        } else if (_house == House.Hearing) {
            return "Hearing";
        } else if (_house == House.Shadows) {
            return "Shadows";
        } else {
            return "Scarred";
        }
    }
}

interface IWorldPassNFT {
    struct TokenData {
        bool __exists;

        House house;
    }

    function setTokenHouse(uint256 _tokenId, House _house) external;

    function getTokenHouse(uint256 _tokenId) external view returns (House);

    function getRemainingHouseSupply(House _house) external view returns (uint256);

    function mintWithHouseTo(address _to, House _house) external;

    function batchMintWithHouseTo(
        address _to,
        uint256 _quantity,
        House _house
    ) external;
}