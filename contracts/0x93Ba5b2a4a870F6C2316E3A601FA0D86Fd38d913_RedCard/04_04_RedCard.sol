//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IKitBag {
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes calldata data
    ) external;
}

interface IMPL {
    function balanceOf(address account) external view returns (uint256);
}

interface IDelegationRegistry {
    function checkDelegateForContract(
        address delegate,
        address vault,
        address contract_
    ) external view returns (bool);
}

function getOneArray(uint256 length) pure returns (uint256[] memory arr) {
    arr = new uint[](length);
    for (uint i = 0; i < length; i++) {
        arr[i] = 1;
    }
}

contract RedCard is Ownable, Pausable {
    IKitBag public kitBag; // KitBag contract
    IMPL public mpl; // MPL contract
    IDelegationRegistry public dc; // Delegation contract

    uint8[2] public cutoffs = [5, 11]; // MPL balance cutoffs to receive multiple comics (1 / 2 / 3)
    uint8[2] public odds = [169, 225]; // Odds of receiving different comics. We use the same odds across comics
    mapping(uint8 => bool) baseIds; // Base IDs of comic covers that can be minted (comic covers come in threes)
    mapping(uint8 => mapping(address => bool)) public claimed; // Whether addresses have claimed different comics

    bool public allowMultipleClaims = false; // Whether users can claim multiple comics

    constructor(
        address _kitBag,
        address _mpl,
        address _dc,
        uint8[] memory _baseIds
    ) {
        kitBag = IKitBag(_kitBag);
        mpl = IMPL(_mpl);
        dc = IDelegationRegistry(_dc);

        for (uint8 i = 0; i < _baseIds.length; i++) {
            baseIds[_baseIds[i]] = true;
        }
    }

    function setBaseId(uint8 _baseId, bool _setting) external onlyOwner {
        baseIds[_baseId] = _setting;
    }

    function setCutoffs(uint8[2] memory _cutoffs) external onlyOwner {
        require(_cutoffs[0] < _cutoffs[1], "RedCard: invalid cutoffs");
        cutoffs = _cutoffs;
    }

    function setOdds(uint8[2] memory _odds) external onlyOwner {
        require(_odds[0] < _odds[1], "Redcard: invalid odds");
        odds = _odds;
    }

    function setAllowMultipleClaims(
        bool _allowMultipleClaims
    ) external onlyOwner {
        allowMultipleClaims = _allowMultipleClaims;
    }

    function mint(uint8 baseId, address vault) public whenNotPaused {
        address requester = msg.sender;

        if (vault != address(0)) {
            bool isDelegateValid = dc.checkDelegateForContract(
                msg.sender,
                vault,
                address(mpl)
            );
            require(isDelegateValid, "invalid delegate-vault pairing");
            requester = vault;
        }

        require(baseIds[baseId], "RedCard: not a valid baseId");
        require(
            !claimed[baseId][requester] || allowMultipleClaims,
            "RedCard: already claimed"
        );

        uint256 balance = mpl.balanceOf(requester);
        require(balance > 0, "RedCard: no MPLs!");

        uint256 pseudoRandom = uint8(
            uint256(
                keccak256(
                    abi.encode(
                        blockhash(block.number - 1),
                        address(this),
                        requester
                    )
                )
            )
        );

        uint256 randomId;

        if (balance < cutoffs[0]) {
            if (pseudoRandom < odds[0]) {
                randomId = baseId;
            } else if (pseudoRandom < odds[1]) {
                randomId = baseId + 1;
            } else {
                randomId = baseId + 2;
            }

            kitBag.mint(requester, randomId, 1, "0x");
        } else if (balance < cutoffs[1]) {
            randomId = pseudoRandom < odds[0] ? baseId + 1 : baseId + 2;
            uint[] memory ids = new uint[](2);
            ids[0] = baseId;
            ids[1] = randomId;
            kitBag.mintBatch(requester, ids, getOneArray(2), "0x");
        } else {
            uint[] memory ids = new uint[](3);
            ids[0] = baseId;
            ids[1] = baseId + 1;
            ids[2] = baseId + 2;
            kitBag.mintBatch(requester, ids, getOneArray(3), "0x");
        }

        claimed[baseId][requester] = true;
    }

    function setPaused(bool _bPaused) external onlyOwner {
        if (_bPaused) _pause();
        else _unpause();
    }
}