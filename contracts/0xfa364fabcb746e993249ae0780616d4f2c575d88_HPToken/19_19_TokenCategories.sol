pragma solidity ^0.5.5;


contract TokenCategories {

    function getTokenCategory(uint256 tokenId) public pure returns (string memory) {
        if (tokenId > 0 && tokenId <= 500) {
            // Token categories for limited stamps sold online
            if (tokenId > 0 && tokenId <= 5) {
                return "1";
            } else if (tokenId > 5 && tokenId <= 25) {
                return "2";
            } else if (tokenId > 25 && tokenId <= 75) {
                return "3";
            } else if (tokenId > 75 && tokenId <= 200) {
                return "4";
            } else if (tokenId > 200 && tokenId <= 500) {
                return "5";
            }
        }

        if (tokenId > 500 && tokenId <= 1495) {
            return "1";
        } else if (tokenId > 1495 && tokenId <= 5475) {
            return "2";
        } else if (tokenId > 5475 && tokenId <= 15425) {
            return "3";
        } else if (tokenId > 15425 && tokenId <= 40300) {
            return "4";
        } else if (tokenId > 40300 && tokenId <= 100000) {
            return "5";
        }
    }
}