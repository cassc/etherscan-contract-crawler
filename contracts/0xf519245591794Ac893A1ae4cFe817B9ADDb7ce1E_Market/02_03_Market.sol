// SPDX-License-Identifier: MIT

/***************************************************************************
          ___        __         _     __           __   __ ___
        / __ \      / /_  _____(_)___/ /____       \ \ / /  _ \
       / / / /_  __/ __/ / ___/ / __  / __  )       \ / /| |
      / /_/ / /_/ / /_  (__  ) / /_/ / ____/         | | | |_
      \____/\____/\__/ /____/_/\__,_/\____/          |_|  \___/
                                       
****************************************************************************/

pragma solidity ^0.8.0;

import "./Ownable.sol";

interface IERC20 {
    function burn(address from, uint256 amount) external;
}

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

contract Market is Ownable {
    address admin = 0x44f7c870fA937578f6eacE3fCD4789726E105354;
    address osycAddress = 0xdDEF9122b0b4d76Df98e60FD97e36e8dC5831079;

    string private constant CONTRACT_NAME = "OSYC Market Contract";
    bytes32 private constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
    bytes32 private constant BUY_TYPEHASH =
        keccak256(
            "Buy(address user,uint256 pid,bool isERC721,address collection,uint16 tokenId,uint16 totalAmount,uint16 amount,uint256 price,address owner)"
        );

    struct BuyInfo {
        uint256 pid;
        bool isERC721;
        address collection;
        uint16 tokenId;
        uint16 totalAmount;
        uint16 amount;
        uint256 price;
        address owner;
    }

    mapping(uint256 => uint16) public mintedFromPid;

    constructor() {}

    function Buy(
        BuyInfo memory buyInfo,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(tx.origin == msg.sender, "Only EOA");

        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(CONTRACT_NAME)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(
                BUY_TYPEHASH,
                msg.sender,
                buyInfo.pid,
                buyInfo.isERC721,
                buyInfo.collection,
                buyInfo.tokenId,
                buyInfo.totalAmount,
                buyInfo.amount,
                buyInfo.price,
                buyInfo.owner
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == admin, "Invalid signatory");

        if (buyInfo.isERC721) {
            require(buyInfo.amount == 1 && mintedFromPid[buyInfo.pid] == 0, "Already sold");
        } else {
            require(buyInfo.amount > 0, "No correct amount");
            require(
                buyInfo.amount > 0 && mintedFromPid[buyInfo.pid] + buyInfo.amount <= buyInfo.totalAmount,
                "Already sold out"
            );
        }

        mintedFromPid[buyInfo.pid] = mintedFromPid[buyInfo.pid] + buyInfo.amount;

        IERC20(osycAddress).burn(msg.sender, buyInfo.price);
        if (buyInfo.isERC721) {
            IERC721(buyInfo.collection).transferFrom(
                buyInfo.owner,
                msg.sender,
                buyInfo.tokenId
            );
        } else {
            IERC1155(buyInfo.collection).safeTransferFrom(
                buyInfo.owner,
                msg.sender,
                buyInfo.tokenId,
                buyInfo.amount,
                ""
            );
        }
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}
