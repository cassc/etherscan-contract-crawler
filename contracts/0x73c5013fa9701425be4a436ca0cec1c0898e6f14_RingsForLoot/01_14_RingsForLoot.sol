// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import 'base64-sol/base64.sol';
import './EIP712Whitelisting.sol';

pragma solidity ^0.8.0;

interface ILoot {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function getRing(uint256 tokenId) external view returns (string memory);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IERC2981 {
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

interface ProxyRegistry {
    function proxies(address) external view returns (address);
}

contract RingsForLoot is ERC1155, IERC2981, Ownable, EIP712Whitelisting {
    enum SaleState {
        Paused,
        OnlyCommon,
        Active
    }
    SaleState public state = SaleState.Paused;

    // The original Loot contract address is used to fetch the ring name
    // by loot bag id, so we don't have to inline the data in this contract
    ILoot private ogLootContract;
    // Loot-compatible contracts that we support. Users can claim a matching
    // ring if they own a token in this contract and `getRing` matches ring's name
    mapping(ILoot => bool) private lootContracts;
    // We only allow claiming one matching ring per bag. This data structure
    // holds the contract/bag ids that were already claimed
    mapping(ILoot => mapping(uint256 => bool)) public bagClaimed;
    // How many rings of each kind were already minted. Exposed via mintedBatched
    // for more efficient querying
    mapping(uint256 => uint256) private _minted;

    // Even though ERC1155 doesn't require these, most services still show this
    // information if it's available
    string public name = 'Rings for Loot';
    string public symbol = 'R4L';

    // IPFS hash of the folder that stores high resolution rings assets
    string public ipfs;

    // STORING RINGS SUPPLY
    // Each token id corresponds to a distinct ring in the Loot universe.
    // Ring id is defined as minimum loot bag id with this particular ring.
    // Unfortunately, given Loot's plucking algorithm, it's impossible to write
    // a function that can produce maximum ring supply given a ring id. So we
    // have to store (ring id, max supply) on the chain. Doing it as a mapping
    // would produce close to 54KB of data, so we need to be clever in the way
    // we pack it. Depending on how rare the ring is, we use a different encoding
    // mechanism.

    // Common rings are indexed by color: Gold, Silver, Bronze, Platinum, Titanium.
    uint256[5] private commonIds = [1, 6, 11, 7, 2];
    uint256[5] private commonMax = [1093, 1178, 1166, 1163, 1112];

    // Epic rings ids are stored as a tightly packed array of uint16
    // Epic rings max supply is stored as a tightly packed array of uint8
    bytes[5] private epicIds;
    bytes[5] private epicMax;

    // Legendary and mythic ring ids are stored as a tightly packed array of uint16
    // The max supply is inferred from the number of times the ring is found in
    // the array. Each legendary ring is duplicated, mythic are one-of-a-kind.
    bytes[5] private legendaryIds;
    bytes[5] private mythicIds;

    // Pricing
    uint256 private constant PRICE_RING_COMMON = 0.02 ether;
    uint256 private constant PRICE_RING_EPIC = 0.06 ether;
    uint256 private constant PRICE_RING_LEGENDARY = 0.1 ether;
    uint256 private constant PRICE_RING_MYTHIC = 0.14 ether;
    uint256 private constant PRICE_FORGE_EPIC = 0.02 ether;
    uint256 private constant PRICE_FORGE_LEGENDARY = 0.04 ether;
    uint256 private constant PRICE_FORGE_MYTHIC = 0.06 ether;

    // Giveaway can only be used once per wallet address
    mapping(address => bool) public whitelistUsed;

    constructor(ILoot[] memory lootsList) ERC1155('') {
        for (uint256 i = 0; i < lootsList.length; i++) {
            if (i == 0) {
                ogLootContract = lootsList[i];
            }
            lootContracts[lootsList[i]] = true;
        }

        // This data is generated and encoded via RingsForLoot-test.ts
        epicIds[0] = hex'00030009000d0016002300330078007d00b1011001ad022e02da038d03f604e0';
        epicIds[1] = hex'002100a600d50156015c0174018301ba024402b702d002d40305032c03ab0429';
        epicIds[2] = hex'002b0059006500730086009a00b600f50150016e01d502050209026302f8032f';
        epicIds[3] = hex'00270031003400490064008a008b00b9012b0133016b017a026f0276028b0615';
        epicIds[4] = hex'0024002e003c004300450047005c009c009e00b300d4010b018a01f202f40350';
        epicMax[0] = hex'111412150f151113111a0f0d120f160b';
        epicMax[1] = hex'16131c0f15120f1a0d180d0911111417';
        epicMax[2] = hex'1712150f1412140d1014111011101118';
        epicMax[3] = hex'1513120f1b1814130f1515161b13110e';
        epicMax[4] = hex'19152019131410181a13110a0f121410';
        legendaryIds[0] = hex'0151015101b401b4039203920558055807500750';
        legendaryIds[1] = hex'00a400a400e900e905e105e10b140b140b5f0b5f132e132e';
        legendaryIds[2] = hex'0125012504cd04cd0894089414f614f6';
        legendaryIds[3] = hex'01b201b205180518056205620bac0bac16171617';
        legendaryIds[4] = hex'02dc02dc06c506c50daa0daa105010501c7b1c7b';
        // prettier-ignore
        mythicIds[0] = hex'00220123013b014c01e002d20325039603a003f903fe041504310448046c053b0561059305c505ee0638063a064c065a069b06a506c306f907050831083b08a70916095e09a00a120a5a0aa00aac0ab50aed0b1f0b280b340b5d0b890bbb0bc40c710c7a0c820cca0cd30cea0d2e0d340d550ef20f120f200f4e0f540f7d0fa410011014105e1070109f10b310d710e81101110d114b1176118111be11c6124f125812a412fe130d1378139413af13b213ec142d147814a214c914de14df14fd1543157f158115901598159a15a916df16f316ff170b171a175a179717e5187418d818ef18fc190a193c194519461a001a911a961abd1af31b1b1bcd1bd61c441c471c911cbd1cda1d031d651d9c1dfa1e391e6e1e8f1ef51f1c';
        // prettier-ignore
        mythicIds[1] = hex'0025007e008200c500df016c01ee01fa02010211024202d802f3033c038203b003b303f70416041f042a0434053e056f05a505b605d505db06240653067d06e407380773079c07d2085e086e087c08b508bd08d70914097209d10a500a5b0a9c0ab10abd0b070b180b1d0b6f0b940c2f0c600c750c8d0cfa0d1f0d260d320d910de80e910e9b0eb00ed80edb0ef80f24104a106f107f109510c5110211261134118c11a011a111cc11d71274128a129212af12d712d9133b1343138413881412142c143a149a14c714ed15511580167016c716fb171017421763177817a117f8182e187619181924192b1967198019a719fa1a3f1a4a1a811ada1b111b2a1b4e1b5c1b621ba41bf11c2a1c701d001d161d361d611d731d781dc51dcb1dcf1e141ea31ea71eee1efd1f29';
        // prettier-ignore
        mythicIds[2] = hex'001d0061007700dc01c4021b0221023c023d024e025e026b02bf02e9030903120358035a036603880424043c04d104dd05c205cc05d3061b06410680069c0766078f07d307d907e907f0082d0844089f08b208d4095709660983098609ac09d209fb0a1b0a4b0b020b660b930bd90c620d1b0d440d8c0db30dc30ddc0ed90f3e0f530f5b0fed0ffc103210bb11c81215132313471350137e13bc13c4140e14331493151b159415de15ec15f015f415fe161b167316a716b117701796179d17cb17e0181818311849189f18a918c918d718ff1956197d19a219d91acd1adc1ae91aea1b361b9c1bec1c871cc11ccd1cd61ce11cf51d141d1b1d311d5a1d621d681d6f1d741d901d9a1dba';
        // prettier-ignore
        mythicIds[3] = hex'004200bf00d30107010e0116013001da01e102030208021402710273029b02b40359037403a903df041104370460048b04aa04e905510554055e0566057205c105ca05f00635066706b5071007200732076a07b60806086508c508e608fd095b099f0a030a220b7e0b810be20c330c350c380c9d0ca80cd40cd60d010d090d280dbb0df00dfc0e060ede0ee80f410fa810ac114e1150115e11c111ed11f711f912041216121f124112681309130f133f137313be14211427142f1459146e155415a715a815b11606164c168f1706182c189518b918c118e518ed194b198919f51a1f1a671a901ac11ad01b401b681b6f1b721b8a1bda1c6f1c8c1c9c1d3c1d551d661d801d9d1dea1def1e0b1e111e181e341e941ea51eb71ebd1ed11f0c1f16';
        // prettier-ignore
        mythicIds[4] = hex'00380044006b00810104011101680170018501bd01c202190288028d02f002ff032b03720390042c045c04b204e60603061d063c064506b806c606db06e5071f07480765078207de082f088008f1090b09250943095f098b09ae09bc09cd09ea0a6d0a920a9f0aa30b210b7f0b960ba60bc90bcd0bcf0be40bf70bfa0c3a0c450c560d5d0de20e400e820e8b0e9d0eae0ec90ef70f520f7e0f910fb20fc40fd5103710561061110c115311641183118711a211fe1208124b131813441349136e13a613aa13cb13df147a14c214d91503150d15341629163f170c17b817f21816184c1856188618a3190e191a191b19341957197a1a171a321a371a511a601a691aa41ad31b2f1b3b1b791ba21beb1c341c7d1ce01d081d121d1f1d201d451d471d8e1e151e471ec91ed51eda1f041f131f1b';
    }

    function purchaseCommon(uint256 amount, bytes calldata signature) public payable {
        require(state == SaleState.OnlyCommon || state == SaleState.Active, 'Sale not active');

        // If signature is provided, treat this call as a candidate for
        // a giveaway for one free random common ring.
        if (signature.length > 0) {
            validateGiveawaySignature(signature);
            require(amount == 1, 'Can only get one');
            require(msg.value == 0, 'Wrong price');
        } else {
            require(amount > 0, 'Buy at least one');
            require(amount <= 26, 'Too many at once');
            require(msg.value == amount * PRICE_RING_COMMON, 'Wrong price');
        }
        require(commonMax[0] + commonMax[1] + commonMax[2] + commonMax[3] + commonMax[4] >= amount, 'Not enough left');

        uint256[5] memory amounts;
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
        for (uint256 i = 0; i < amount; i++) {
            // The inner loop tries to find a common ring that still has
            // supply left.
            while (true) {
                require(rand > 0, 'ran out of randomness');
                uint256 color = rand % 5;
                // Advance forward to find the next available common ring more efficiently,
                // in case some of them ran out.
                rand += 1;
                if (commonMax[color] > 0) {
                    amounts[color] += 1;
                    commonMax[color] -= 1;
                    break;
                }
            }
            rand /= 5;
        }

        for (uint256 i = 0; i < 5; i++) {
            if (amounts[i] > 0) {
                _minted[commonIds[i]] += amounts[i];
                // At the time of writing this contract, many cetralized tools had issues
                // with understanding `TransferBatch` event :/
                _mint(msg.sender, commonIds[i], amounts[i], '');
            }
        }
    }

    function purchaseMatching(
        ILoot loot,
        uint256 bagId,
        uint256 ringId,
        bytes calldata signature
    ) public payable {
        require(lootContracts[loot], 'Not compatible');
        require(loot.ownerOf(bagId) == msg.sender, 'Not owner');
        require(
            keccak256(abi.encodePacked(loot.getRing(bagId))) ==
                keccak256(abi.encodePacked(ogLootContract.getRing(ringId))),
            'Wrong ring'
        );
        require(!bagClaimed[loot][bagId], 'Already claimed');
        bagClaimed[loot][bagId] = true;

        uint256 price;

        // These are taken from Loot to get an approximation of how rare the matching
        // ring is. We need this information because each ring max supply is stored
        // differently depending on rarity.
        uint256 rand = uint256(keccak256(abi.encodePacked('RING', Strings.toString(ringId))));
        uint256 greatness = rand % 21;
        uint256 color = rand % 5;

        require(state == SaleState.Active || (state == SaleState.OnlyCommon && greatness <= 14), 'Sale not active');

        if (greatness <= 14) {
            // Common
            require(commonMax[color] > 0, 'Not in stock');
            price = PRICE_RING_COMMON;
            commonMax[color] -= 1;
        } else if (greatness < 19) {
            // Epic
            price = PRICE_RING_EPIC;
            (bool found, uint256 index) = findRingIndex(epicIds[color], ringId);
            require(found, 'Not in stock');
            uint8 max = uint8(epicMax[color][index]);
            max -= 1;
            if (max > 0) {
                epicMax[color][index] = bytes1(max);
            } else {
                removeUint16At(epicIds[color], index * 2);
                epicMax[color][index] = epicMax[color][epicMax[color].length - 1];
                epicMax[color].pop();
            }
        } else {
            // Legendary and Mythic. Unfortunately we don't know which one it is, since
            // it's based on rarity, not greatness. So check both:
            (bool found, uint256 index) = findRingIndex(legendaryIds[color], ringId);
            if (found) {
                price = PRICE_RING_LEGENDARY;
                removeUint16At(legendaryIds[color], index * 2);
            } else {
                price = PRICE_RING_MYTHIC;
                (found, index) = findRingIndex(mythicIds[color], ringId);
                require(found, 'Not in stock');
                removeUint16At(mythicIds[color], index * 2);
            }
        }

        // If signature is provided, treat this call as a candidate for
        // a giveaway for one matching ring.
        if (signature.length > 0) {
            validateGiveawaySignature(signature);
            price = 0;
        }

        require(msg.value == price, 'Wrong price');

        _minted[ringId] += 1;
        _mint(msg.sender, ringId, 1, '');
    }

    function forge(uint256 color, uint256 amount) public payable {
        require(state == SaleState.Active, 'Sale not active');
        require(color < 5, 'Not a common ring');
        uint256 ringIdToBurn = commonIds[color];

        bytes storage data;
        if (amount == 2) {
            require(msg.value == PRICE_FORGE_EPIC, 'Wrong price');
            data = epicIds[color];
        } else if (amount == 3) {
            require(msg.value == PRICE_FORGE_LEGENDARY, 'Wrong price');
            data = legendaryIds[color];
        } else if (amount == 4) {
            require(msg.value == PRICE_FORGE_MYTHIC, 'Wrong price');
            data = mythicIds[color];
        } else {
            revert('Wrong amount of rings to burn');
        }

        (uint256 ringIdToMint, uint256 index) = pickRandomRing(data);
        uint256 ringsLeft;
        if (amount == 2) {
            ringsLeft = uint8(epicMax[color][index / 2]) - 1;
            epicMax[color][index / 2] = bytes1(uint8(ringsLeft));
        }
        if (ringsLeft == 0) {
            removeUint16At(data, index);
            if (amount == 2) {
                epicMax[color][index / 2] = epicMax[color][epicMax[color].length - 1];
                epicMax[color].pop();
            }
        }

        _minted[ringIdToMint] += 1;
        _burn(msg.sender, ringIdToBurn, amount);
        _mint(msg.sender, ringIdToMint, 1, '');
    }

    function mintedBatched(uint256[] calldata ids) public view returns (uint256[] memory counts) {
        counts = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            counts[i] = _minted[ids[i]];
        }
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(_minted[tokenId] > 0, 'Ring does not exist');

        // Some Loot rings have quotes in them, so we need to escape these
        // to not break JSON. 34 is ", 92 is \
        bytes memory ringName = bytes(ogLootContract.getRing(tokenId));
        if (uint8(ringName[0]) == 34) {
            bytes memory escRingName = new bytes(ringName.length + 2);
            uint256 ei = 0;
            for (uint256 i = 0; i < ringName.length; i++) {
                if (uint8(ringName[i]) == 34) {
                    escRingName[ei++] = bytes1(uint8(92));
                }
                escRingName[ei++] = ringName[i];
            }
            ringName = escRingName;
        }

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        ringName,
                        '", "description": "Rings (for Loot) is the first and largest 3D interpretation of an entire category in Loot. Adventurers, builders, and artists are encouraged to reference Rings (for Loot) to further expand on the imagination of Loot.", "image": "ipfs://',
                        ipfs,
                        '/',
                        Strings.toString(tokenId),
                        '.jpg"}'
                    )
                )
            )
        );
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function pickRandomRing(bytes storage data) internal view returns (uint256 result, uint256 index) {
        require(data.length > 0, 'data is empty');
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp)));
        index = rand % data.length;
        index -= (index % 2);
        result = readUint16At(data, index);
    }

    function findRingIndex(bytes storage data, uint256 ringId) internal view returns (bool found, uint256 index) {
        for (uint256 i = 0; i < data.length / 2; i++) {
            if (uint8(data[i * 2]) == ((ringId >> 8) & 0xFF) && uint8(data[i * 2 + 1]) == (ringId & 0xFF)) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function readUint16At(bytes storage data, uint256 index) internal view returns (uint16 result) {
        result = (uint16(uint8(data[index])) << 8) + uint8(data[index + 1]);
    }

    function writeUint16At(
        bytes storage data,
        uint256 index,
        uint16 value
    ) internal {
        data[index] = bytes1(uint8(value >> 8));
        data[index + 1] = bytes1(uint8(value & 0xFF));
    }

    function removeUint16At(bytes storage data, uint256 index) internal {
        require(data.length > 0, 'data is empty');
        data[index] = data[data.length - 2];
        data[index + 1] = data[data.length - 1];
        data.pop();
        data.pop();
    }

    function validateGiveawaySignature(bytes calldata signature) internal returns (bool) {
        requiresWhitelist(signature);
        require(!whitelistUsed[msg.sender], 'Already used');
        whitelistUsed[msg.sender] = true;
        return true;
    }

    // Interfaces

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        receiver = owner();
        royaltyAmount = (salePrice * 5) / 100;
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Allow easier listing for sale on OpenSea. Based on
        // https://github.com/ProjectOpenSea/opensea-creatures/blob/f7257a043e82fae8251eec2bdde37a44fee474c4/migrations/2_deploy_contracts.js#L29
        if (block.chainid == 4) {
            if (ProxyRegistry(0xF57B2c51dED3A29e6891aba85459d600256Cf317).proxies(owner) == operator) {
                return true;
            }
        } else if (block.chainid == 1) {
            if (ProxyRegistry(0xa5409ec958C83C3f309868babACA7c86DCB077c1).proxies(owner) == operator) {
                return true;
            }
        }

        return ERC1155.isApprovedForAll(owner, operator);
    }

    // Admin

    function setState(SaleState newState) public onlyOwner {
        state = newState;
    }

    function setIpfs(string calldata newIpfs) public onlyOwner {
        ipfs = newIpfs;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function withdrawAllERC20(IERC20 erc20Token) public onlyOwner {
        require(erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this))));
    }
}