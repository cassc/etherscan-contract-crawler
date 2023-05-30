// SPDX-License-Identifier: MIT     
//                          ,,╓╔σ╦φφ╦ε╔╓,
//                     ╓╗▒╬╠╠╠╠╠▒▒▒▒▒▒▒▒▒▒▒╠▒╦,
//                 ,#╣╬╬╬╬╠╠╠╠╠▒▒▒▒▒▒▒▒▒▒▒░░░░░░╠≥,
//               ╔╣╬╬╬╬╬╬╠╠╠╠╠▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░╠╔
//             é╣╬╬╬╬╬╬╬╠╠╠╠╠▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░▒≥
//           ╓╣╬╬╬╬╬╬╬╬╬╠╠╠╠▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░▒╓
//          #╬╬╬╬╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠░░░░╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠
//         ╠╬╬╬╬╬╠╠╠╙""""""╫██████▌╠╠╠░░░░╠╠╠╙""""""╟██████▌╠╠╠
//        ╔╠╬╬╬╬╬╠╠╠       ╫██████▌╠╠╠░░░▒╠╠╠       ╟███████╠╠╠
//    ▒▒▒▒╠╠╠╠▒╠▒╠╠╠       ╫██████▌╠╠╠╠╠╠╠╠╠╠       ╟███████╠╠╠
//    ╠╠╠╠▒▒▒▒▒▒▒╠╠╠       ╫██████▌╠╠╠╩╩╩╠╠╠╠       ╟███████╠╠╠
//    ╠╠╠╠╠╠╠╬╬╬╬╠╠╠       ╫██████▌╠╠╠▒▒▒▒╠╠╠       ╟███████╠╠╠
//    ╠╠╠▒╠╠╠╠╬╬╬╠╠╠       ╫██████▌╠╠╠▒▒▒▒╠╠╠       ╟███████╠╠╠
//    ╠╠╠▒╠╠╠╠╠╬╬╠╠╠       ╫██████▌╠╠╠▒▒▒╠╠╠╠       ╟███████╠╠╠
//       ╘╠▒╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠▒▒▒╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠
//        ╠▒▒╠╠╠╠╠╠╠▒▒╬╬╬╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╙╙╙
//         ╬▒▒╠╠╠╠╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╬╬
//          ╬▒╠▒╠╠╠╠╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╠╬╬╬╬╬╬╬╬╬╬╠
//           ╚╠▒╠╠╠╠╠╠╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╝
//            └╬╠▒▒╠╠╠╠╠╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╙
//              └╣╠▒▒▒╠╠╠╠╠╠╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╙
//                 ╙╬╠▒▒╠╠╠╠╠╠╠╠╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╩`
//                    ╙╝╠▒▒╠╠╠╠╠╠╠╠╠╠╠╠╬╬╬╬╬╬╬╝╙
//                         "╙╚╩╠╠╠╠╠╠╠╠╩╩╙╙
    


pragma solidity ^0.8.15;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/INogDescriptor.sol";
import "./library/Structs.sol";

interface AllowListCollectionInterface {
    function balanceOf(address owner) external view returns (uint256);
}

contract Zorggles is ERC721A, Ownable {
    /* 
    ⌐◨—————————————————————————————————————————————————————————————◨
                                set state
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */

    using Counters for Counters.Counter;
    uint256 public price = 0.023 ether;
    bool public publicMintActive = false;
    bool public allowListActive = false;
    address public withdrawReceiver;

    INogDescriptor public descriptor;
    Structs.NogStyle[] private nogStyles;

    address[] public allowListContractAddresses;
    AllowListCollectionInterface[] allowListContracts;

    mapping(uint256 => Structs.Nog) internal nogSeeds;

    /*
    ⌐◨—————————————————————————————————————————————————————————————◨
                              set up contract
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */

    constructor(
        string memory tokenName,
        string memory tokenSymbol
    ) ERC721A(tokenName, tokenSymbol) {}

    error MissingTokenId(uint256 tokenId, uint256 nextToken);
    event DescriptorUpdated(INogDescriptor descriptor);
    event AllowListUpdated(address contractAddress);
    event ZorggleTypeUpdated(
        uint32 tokenId,
        uint16 zorggleTypeIndex,
        address ownerAddress
    );
    event ZorggleNogTypeUpdated(
        uint32 tokenId,
        uint16 nogTypeIndex,
        address ownerAddress
    );

    function setDescriptor(INogDescriptor _descriptor) public onlyOwner {
        descriptor = _descriptor;
        emit DescriptorUpdated(_descriptor);
    }

    function setAllowListContracts(
        address[] memory contractAddresses
    ) public onlyOwner {
        for (uint i = 0; i < contractAddresses.length; i++) {
            allowListContractAddresses.push(contractAddresses[i]);
            emit AllowListUpdated(contractAddresses[i]);
        }
    }

    /*
    ⌐◨—————————————————————————————————————————————————————————————◨
                               mint
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */

    function internalMint(address receiver, uint256 quantity) internal {
        for (uint256 i = 0; i < quantity; i++) {
            nogSeeds[_nextTokenId()] = constructTokenId(
                _nextTokenId(),
                receiver
            );
            _safeMint(receiver, 1);
        }
    }

    function mint(uint256 quantity) external payable {
        require(publicMintActive, "Public mint not active.");
        require(msg.value >= quantity * price, "Wrong ETH value sent.");
        internalMint(msg.sender, quantity);
    }

    function allowListMint(uint256 quantity) external payable {
        require(allowListActive, "Allow list mint not active.");
        require(isOnAllowList(msg.sender), "Not on allow list");
        require(msg.value >= quantity * price, "Wrong ETH value sent.");
        internalMint(msg.sender, quantity);
    }

    function isOnAllowList(
        address sender
    ) public view returns (bool allowListStatus) {
        allowListStatus = false;
        for (uint i = 0; i < allowListContractAddresses.length; i++) {
            if (
                AllowListCollectionInterface(allowListContractAddresses[i])
                    .balanceOf(sender) > 0
            ) {
                allowListStatus = true;
            }
        }
    }

    /* 
    ⌐◨—————————————————————————————————————————————————————————————◨
                            construct nft
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId))
            revert MissingTokenId({
                tokenId: tokenId,
                nextToken: _nextTokenId()
            });

        Structs.Nog memory nog = nogSeeds[tokenId];
        address ownerAddress = ownerOf(tokenId);
        return descriptor.constructTokenURI(nog, tokenId, ownerAddress);
    }

    function constructTokenId(
        uint256 tokenId,
        address minterAddress
    ) internal view returns (Structs.Nog memory) {
        return
            Structs.Nog({
                minterAddress: minterAddress,
                zorggleType: uint16(0),
                nogStyle: uint16(
                    uint256(descriptor.getPseudorandomness(tokenId, 13))
                ) % descriptor.getStylesCount(),
                colorPalette: [
                    uint16(
                        uint256(descriptor.getPseudorandomness(tokenId, 17))
                    ) % 7,
                    uint16(
                        uint256(descriptor.getPseudorandomness(tokenId, 23))
                    ) % 7,
                    uint16(
                        uint256(descriptor.getPseudorandomness(tokenId, 41))
                    ) % 7,
                    uint16(
                        uint256(descriptor.getPseudorandomness(tokenId, 67))
                    ) % 7,
                    uint16(
                        uint256(descriptor.getPseudorandomness(tokenId, 73))
                    ) % 7,
                    uint16(
                        uint256(descriptor.getPseudorandomness(tokenId, 79))
                    ) % 7,
                    uint16(
                        uint256(descriptor.getPseudorandomness(tokenId, 97))
                    ) % 5
                ]
            });
    }

    /*
    ⌐◨—————————————————————————————————————————————————————————————◨
                           utility functions
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function isStringEmpty(string memory val) internal pure returns (bool) {
        bytes memory checkString = bytes(val);
        if (checkString.length > 0) {
            return false;
        } else {
            return true;
        }
    }

    /*
    ⌐◨—————————————————————————————————————————————————————————————◨
                        token owner functions
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */

    /// @notice Set the Zorb SVG for a given token ID. Only accessible by token owner.
    /// @param tokenId The token ID to set the Zorb type for
    /// @param zorbTypeIndex The index of the new zorb type to use
    function setZorggleType(uint32 tokenId, uint16 zorbTypeIndex) public {
        address ownerAddress = ownerOf(tokenId);
        require(msg.sender == ownerAddress, "Rejected: not token owner");
        require(
            zorbTypeIndex <= descriptor.getZorggleTypesCount(),
            "Rejected: must be a valid zorggle type index"
        );
        nogSeeds[tokenId].zorggleType = zorbTypeIndex;

        emit ZorggleTypeUpdated(tokenId, zorbTypeIndex, ownerAddress);
    }

    /// @notice Set the Zorb SVG for a given token ID. Only accessible by token owner.
    /// @param tokenId The token ID to set the noggle type for
    /// @param nogTypeIndex The index of the new noggle type to use
    function setNogType(uint32 tokenId, uint16 nogTypeIndex) public {
        address ownerAddress = ownerOf(tokenId);
        require(msg.sender == ownerAddress, "Rejected: not token owner");

        if (nogTypeIndex <= descriptor.getStylesCount()) {
            nogSeeds[tokenId].nogStyle = nogTypeIndex;
        } else {
            nogSeeds[tokenId].nogStyle =
                uint16(uint256(descriptor.getPseudorandomness(tokenId, 13))) %
                descriptor.getStylesCount();
        }

        emit ZorggleNogTypeUpdated(tokenId, nogTypeIndex, ownerAddress);
    }

    /*
    ⌐◨—————————————————————————————————————————————————————————————◨
                       contract owner functions
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */

    function togglePublicMint() external onlyOwner {
        publicMintActive = !publicMintActive;
    }

    function toggleAllowListActive() external onlyOwner {
        allowListActive = !allowListActive;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setWithdrawReceiver(address _withdrawReceiver) external onlyOwner {
        withdrawReceiver = _withdrawReceiver;
    }

    function ownerMintForOthers(
        uint256 quantity,
        address receiver
    ) external onlyOwner {
        for (uint256 i = 0; i < quantity; i++) {
            nogSeeds[_nextTokenId()] = constructTokenId(
                _nextTokenId(),
                receiver
            );
            _safeMint(msg.sender, 1);
        }
    }

    function withdraw() external onlyOwner {
        payable(withdrawReceiver).transfer(address(this).balance);
    }
}