// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

//     ███████╗██╗    ██╗ █████╗ ██████╗
//     ██╔════╝██║    ██║██╔══██╗██╔══██╗
//     ███████╗██║ █╗ ██║███████║██████╔╝
//     ╚════██║██║███╗██║██╔══██║██╔═══╝
//     ███████║╚███╔███╔╝██║  ██║██║
//     ╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝
//
//           The easiest way to
//         trade NFTs on Ethereum.

contract SwapFree is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    struct NFT {
        uint256 tokenId;
        address contractAddress;
        uint256 tokenStandard;
    }

    struct Trade {
        uint256 id;
        address person1;
        address person2;
        uint256 person1Wei;
        uint256 person2Wei;
        uint256 person1NftCount;
        uint256 person2NftCount;
        uint256 status; // 0=pending, 1=accepted, 2=rejected
    }

    struct ReturnedTrade {
        uint256 id;
        address person1;
        address person2;
        uint256 person1Wei;
        uint256 person2Wei;
        NFT[] person1Nfts;
        NFT[] person2Nfts;
        uint256 status;
    }

    // tradeId => nftIndex
    mapping(uint256 => mapping(uint256 => NFT)) person1Nft;
    mapping(uint256 => mapping(uint256 => NFT)) person2Nft;

    Counters.Counter private tradeId;
    mapping(uint256 => Trade) public trades;

    address DEV_WALLET;
    address SWAP_WALLET;

    constructor(address devWallet, address swapWallet) {
        DEV_WALLET = devWallet;
        SWAP_WALLET = swapWallet;
    }

    function createTrade(
        Trade memory newTrade,
        NFT[] memory _person1Nfts,
        NFT[] memory _person2Nfts
    ) external payable {
        require(newTrade.person1 == msg.sender, "INVALID SENDER");

        require(
            validateOwnership(msg.sender, _person1Nfts),
            "SENDER DOES NOT OWN TOKEN (CREATE)"
        );

        require(
            validateOwnership(newTrade.person2, _person2Nfts),
            "RECEIVER DOES NOT OWN TOKEN"
        );

        newTrade.id = tradeId.current();
        newTrade.person1Wei = msg.value;
        trades[newTrade.id] = newTrade;

        for (uint256 i = 0; i < _person1Nfts.length; i++) {
            person1Nft[newTrade.id][i] = _person1Nfts[i];
        }
        for (uint256 i = 0; i < _person2Nfts.length; i++) {
            person2Nft[newTrade.id][i] = _person2Nfts[i];
        }
        tradeId.increment();
    }

    function validateOwnership(address person, NFT[] memory nfts)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < nfts.length; i++) {
            NFT memory nft = nfts[i];

            if (ERC721(nft.contractAddress).ownerOf(nft.tokenId) != person) {
                return false;
            }
        }
        return true;
    }

    function getCurrentTradeId() public view returns (uint256) {
        return tradeId.current();
    }

    function getTradeById(uint256 _tradeId)
        public
        view
        returns (ReturnedTrade memory)
    {
        Trade memory trade = trades[_tradeId];
        uint256 _person1NftCount = trade.person1NftCount;
        NFT[] memory _person1Nfts = new NFT[](_person1NftCount);

        for (uint256 i = 0; i < _person1NftCount; i++) {
            _person1Nfts[i] = person1Nft[_tradeId][i];
        }

        uint256 _person2NftCount = trade.person2NftCount;
        NFT[] memory _person2Nfts = new NFT[](_person2NftCount);

        for (uint256 i = 0; i < _person2NftCount; i++) {
            _person2Nfts[i] = person2Nft[_tradeId][i];
        }

        return
            ReturnedTrade(
                trade.id,
                trade.person1,
                trade.person2,
                trade.person1Wei,
                trade.person2Wei,
                _person1Nfts,
                _person2Nfts,
                trade.status
            );
    }

    function getTradesBySender(address sender)
        public
        view
        returns (ReturnedTrade[] memory)
    {
        ReturnedTrade[] memory result = new ReturnedTrade[](tradeId.current());
        uint256 count;
        for (uint256 i = 0; i <= tradeId.current(); i++) {
            Trade memory currentTrade = trades[i];
            if (currentTrade.person1 == sender) {
                result[count] = getTradeById(currentTrade.id);
                count++;
            }
        }
        return result;
    }

    function getTradesByReceiver(address receiver)
        public
        view
        returns (ReturnedTrade[] memory)
    {
        ReturnedTrade[] memory result = new ReturnedTrade[](tradeId.current());
        uint256 count;
        for (uint256 i = 0; i <= tradeId.current(); i++) {
            Trade memory currentTrade = trades[i];
            if (currentTrade.person2 == receiver) {
                result[count] = getTradeById(currentTrade.id);
                count++;
            }
        }
        return result;
    }

    function acceptTrade(uint256 _tradeId) public payable nonReentrant {
        Trade storage trade = trades[_tradeId];
        require(msg.value >= trade.person2Wei, "MUST INCLUDE ETHER FOR TRADE");
        ReturnedTrade memory tradeWithNfts = getTradeById(_tradeId);
        require(msg.sender == trade.person2, "ONLY RECEIVER CAN ACCEPT");
        require(trade.status == 0, "INVALID TRADE STATUS");

        require(
            validateOwnership(trade.person1, tradeWithNfts.person1Nfts),
            "SENDER DOES NOT OWN TOKEN"
        );

        require(
            validateOwnership(trade.person2, tradeWithNfts.person2Nfts),
            "RECEIVER DOES NOT OWN TOKEN"
        );

        //TRANSFER ETHER
        if (trade.person1Wei > 0) {
            payable(trade.person2).transfer(trade.person1Wei);
        }
        if (trade.person2Wei > 0) {
            payable(trade.person1).transfer(trade.person2Wei);
        }

        //TRANSFER NFTS
        for (uint256 i = 1; i <= 2; i++) {
            NFT[] memory currentPersonNfts = i == 1
                ? tradeWithNfts.person1Nfts
                : tradeWithNfts.person2Nfts;
            for (uint256 j = 0; j < currentPersonNfts.length; j++) {
                NFT memory currentNft = currentPersonNfts[j];
                address sender = i == 1 ? trade.person1 : trade.person2;
                address receiver = i == 1 ? trade.person2 : trade.person1;

                if (currentNft.tokenStandard == 721) {
                    ERC721(currentNft.contractAddress).safeTransferFrom(
                        sender,
                        receiver,
                        currentNft.tokenId
                    );
                }

                // if (currentNft.tokenStandard == 1155) {
                //     ERC1155(currentNft.contractAddress).safeTransferFrom(
                //         trade.person1,
                //         trade.person2,
                //         tradeWithNfts.person1Nfts[i].id,
                //         0,
                //         -62
                //     );
                // }
            }
        }
        trade.status = 1;
    }

    function cancelTrade(uint256 tradeIdNumber) external nonReentrant {
        Trade storage trade = trades[tradeIdNumber];
        require(msg.sender == trade.person1, "ONLY SENDER CAN CANCEL");
        require(trade.status == 0, "INVALID TRADE STATUS");

        trade.status = 2;
    }

    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "ZERO_BALANCE");
        uint256 devShare = (address(this).balance * 25) / 100;
        uint256 swapShare = (address(this).balance * 75) / 100;
        payable(DEV_WALLET).transfer(devShare);
        payable(SWAP_WALLET).transfer(swapShare);
    }
}