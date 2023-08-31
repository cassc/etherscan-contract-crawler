// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract SODAContract {
    function ownerOf(uint tokenId) public view virtual returns (address) {
    }
}

contract CansContract {
    function balanceOfAccount(address account) public view virtual returns (uint32[7] memory) { }
    function burn(uint[] calldata amounts) external { }
    function safeBatchTransferFrom( address from, address to, uint[] memory ids, uint[] memory amounts, bytes memory data) public virtual { }
}

error NotOwnerOfSODA();
error MaxMutationsUsed();
error FlavorAlreadyUsed();
error ToUintOutOfBounds();
error OnlyAcceptsCans();
error NotEnoughFlavors();
error TooManyFlavors();
error InvalidFlavorQuantity();
error DerangementDisabled();

contract DerangedApes is ERC721A, Ownable, ReentrancyGuard, IERC1155Receiver {
    using Strings for uint256; 

    string private baseURI;
    CansContract private immutable cans;
    SODAContract private immutable soda;
    bool public mintEnabled = false;

    //mapping(uint => Derangements) private derangementData;
    // OG ID => Mutant IDs
    mapping(uint => uint32[2]) private derangements;
    // Mutant ID => Flavors bitfield
    mapping(uint32 => uint32) private flavorsUsed;

    event Derangement(uint indexed mutantID, uint indexed sodaID, uint[] flavors);

    constructor(address sodaAddress, address cansAddress) ERC721A("DerangedApes", "SODeranged") {
        soda = SODAContract(sodaAddress);
        cans = CansContract(cansAddress);
    }

    function mutateSODA(uint id, uint[] calldata flavors) external nonReentrant {
        if(!mintEnabled) { revert DerangementDisabled(); }
        if(soda.ownerOf(id) != msg.sender) { revert NotOwnerOfSODA(); }
        if(flavors.length == 0) { revert NotEnoughFlavors(); }
        if(flavors.length > 5) { revert TooManyFlavors(); }

        uint32[2] memory dr = derangements[id];
        if(dr[1] != 0) { revert MaxMutationsUsed(); }

        uint32 claimedFlavors = uint32(flavorsUsed[dr[0]]) | uint32(flavorsUsed[dr[1]]);
        uint32 chosenFlavors = 0;
        uint32 f = 0;

        uint[] memory burnArr = new uint[](flavors.length);
        for(uint i = 0; i < flavors.length; i++) {
            f = uint32(flavors[i]);

            if(getBit(claimedFlavors, f) != 0) {
                revert FlavorAlreadyUsed();
            }

            chosenFlavors = setBit(chosenFlavors, f);
            burnArr[i] = 1;
        }
        delete claimedFlavors;
        delete f;

        _safeMint(msg.sender, 1);
        cans.safeBatchTransferFrom(msg.sender, address(this), flavors, burnArr, "");
        uint32 drId = uint32(totalSupply());

        if(dr[0] == 0) {
            dr[0] = drId;
        }
        else {
            dr[1] = drId;
        }

        flavorsUsed[drId] = chosenFlavors;
        derangements[id] = dr;

        emit Derangement(uint(drId), id, flavors);
    }

    function toggleMintEnabled() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function getBit(uint32 _packedBools, uint32 _boolNumber) private pure returns(uint32) {
        return (_packedBools >> _boolNumber) & 1;
    }

    function setBit(uint32 _packedBools, uint32 _boolNumber) private pure returns(uint32) {
        return _packedBools | uint32(1) << _boolNumber;
    }


    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function toUint256(bytes memory _bytes)
      internal
      pure
      returns (uint256 value) {

        assembly {
          value := mload(add(_bytes, 0x20))
        }
    }

    function timesMutated(uint sodaId) external view returns (uint) {
        if(derangements[sodaId][0] == 0) {
            return 0;
        }

        if(derangements[sodaId][1] == 0) {
            return 1;
        }
        return 2;
    }

    function flavorsConsumed(uint sodaId) external view returns (uint[] memory) {
        uint32[2] memory mutants = derangements[sodaId];
        if(mutants[0] == 0) {
            return new uint[](0);
        }

        uint32 flavBits = flavorsUsed[mutants[0]] | flavorsUsed[mutants[1]];

        uint flavorCt;
        for(uint i=0; i<7;i++) {
            if(getBit(flavBits, uint32(i))==1) {
                flavorCt++;
            }
        }

        uint[] memory flavors = new uint[](flavorCt);
        flavorCt=0;
        for(uint i=0; i<7;i++) {
            if(getBit(flavBits, uint32(i))==1) {
                flavors[flavorCt]=i;
                flavorCt++;
            }
        }

        return flavors;
    }

    function derangementFlavors(uint mutantId) external view returns (uint[] memory) {
        uint32 flavBits = flavorsUsed[uint32(mutantId)];

        uint flavorCt;
        for(uint i=0; i<7;i++) {
            if(getBit(flavBits, uint32(i))==1) {
                flavorCt++;
            }
        }

        uint[] memory flavors = new uint[](flavorCt);
        flavorCt=0;
        for(uint i=0; i<7;i++) {
            if(getBit(flavBits, uint32(i))==1) {
                flavors[flavorCt]=i;
                flavorCt++;
            }
        }

        return flavors;
    }

    function getDerangedIds(uint sodaId) external view returns (uint32[2] memory) {
        uint32[2] memory dr = derangements[sodaId];
        return dr;
    }


    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        bytes memory uri = bytes(_baseURI());
        return
            uri.length > 0
                ? string(
                    bytes.concat(uri, bytes(tokenId.toString()), bytes(".json"))
                )
                : "";
    }

    function burnCans() external onlyOwner {
        uint32[7] memory balance = cans.balanceOfAccount(address(this));
        uint[] memory unpacked = new uint[](7);

        for (uint i = 0; i < 7; i++) {
            unpacked[i] = balance[i];
        }

        cans.burn(unpacked);
    }

    function onERC1155Received(address operator, address from, uint id, uint value, bytes calldata data) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address operator, address from, uint[] calldata ids, uint[] calldata values, bytes calldata data) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}