// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC1155 {
    function balanceOf(
        address owner,
        uint256 id
    ) external view returns (uint256 balance);

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external;
}

interface IGTC {
    function transfer(address recipient, uint256 amount) external;
}

contract GarbageNFTS is Ownable {
    uint256 public fee = 2000000000000000;
    address public feeReceiver = 0xe78D3AFD0649fB489148f154Bf01E72C77EFcfBE;
    address public nftReceiver = 0xe78D3AFD0649fB489148f154Bf01E72C77EFcfBE;
    address public GarbageTrolls = 0xd09149BF41DC121B1C4B835ec8Fae22031B5cC47;

    function setGarbageTrolls(address _address) external onlyOwner {
        GarbageTrolls = _address;
    }

    function isOwnerOfAllOrApproved(
        address[] memory _tokenAddresses,
        uint256[] memory _tokenIds,
        uint256[] memory _tokenTypes
    ) public view returns (bool) {
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            IERC721 token = IERC721(_tokenAddresses[i]);
            bool isERC1155 = _tokenTypes[i] == 1;
            bool isApproved = (
                token.isApprovedForAll(msg.sender, address(this))
            );

            if (!isERC1155) {
                if (token.ownerOf(_tokenIds[i]) != msg.sender) {
                    return false;
                }
            } else {
                IERC1155 token1155 = IERC1155(_tokenAddresses[i]);

                if (token1155.balanceOf(msg.sender, _tokenIds[i]) == 0) {
                    return false;
                }
            }

            if (!isApproved) {
                return false;
            }
        }
        return true;
    }

    function dumpNfts(
        address[] memory _tokenAddresses,
        uint256[] memory _tokenIds,
        uint256[] memory _tokenTypes
    ) external payable {
        // require(
        //     isOwnerOfAllOrApproved(_tokenAddresses, _tokenIds, _tokenTypes),
        //     "Not an Owner of an Asset"
        // );
        require(msg.value >= fee, "Pay Fee to Proceed");
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            // bool isERC1155 = _tokenTypes[i] == 1;
            if (_tokenTypes[i] == 1) {
                IERC1155 token = IERC1155(_tokenAddresses[i]);
                
                token.safeTransferFrom(
                    msg.sender,
                    nftReceiver,
                    _tokenIds[i],
                    token.balanceOf(msg.sender, _tokenIds[i]),
                    ""
                );
            } else {
              
                IERC721(_tokenAddresses[i]).transferFrom(msg.sender, nftReceiver, _tokenIds[i]);
            }
        }
        
        IGTC(GarbageTrolls).transfer(msg.sender, 1000000000000000000);
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
    }

    function setNftReceiver(address _nftReceiver) external onlyOwner {
        nftReceiver = _nftReceiver;
    }

    function withdraw() external onlyOwner {
        payable(feeReceiver).transfer(address(this).balance);
    }
}