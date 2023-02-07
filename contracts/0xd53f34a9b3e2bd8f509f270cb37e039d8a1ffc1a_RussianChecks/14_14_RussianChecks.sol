// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC1155} from "openzeppelin/token/ERC1155/ERC1155.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {LibPRNG} from "solady/utils/LibPRNG.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {Base64} from "openzeppelin/utils/Base64.sol";

/// @author SEIZOR (https://twitter.com/artseizor)
contract RussianChecks is ERC1155, Ownable {
    using Strings for uint256;

    string public name = "RussianChecks";
    string public symbol = "RUSCHK";

    constructor(string memory _uri, uint256 _oeEndDate) ERC1155(_uri) {
        oeEndDate = _oeEndDate;
        uint256[] memory ids = new uint256[](80);
        uint256[] memory amounts = new uint256[](80);

        for (uint256 i = 0; i < 80; i++) {
            ids[i] = i;
            amounts[i] = 1;
        }

        _mintBatch(msg.sender, ids, amounts, "");
    }

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public numberMinted;

    /*//////////////////////////////////////////////////////////////
                                 CONFIG
    //////////////////////////////////////////////////////////////*/

    uint256 public maxPerWallet = 10;
    uint256 public oeEndDate;

    function setMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setOeEndDate(uint256 _oeEndDate) public onlyOwner {
        oeEndDate = _oeEndDate;
    }

    function setUri(string memory _uri) public onlyOwner {
        _setURI(_uri);
    }

    /*//////////////////////////////////////////////////////////////
                                  BURN
    //////////////////////////////////////////////////////////////*/

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _burn(from, id, amount);
    }

    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _burnBatch(from, ids, amounts);
    }

    /*//////////////////////////////////////////////////////////////
                                  MINT
    //////////////////////////////////////////////////////////////*/

    function ownerMint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        _mint(to, id, amount, data);
    }

    function ownerMintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        uint256 idsLength = ids.length;
        for (uint256 i = 0; i < idsLength; i++) {
            if (amounts[i] == 0) {
                revert("Amounts must be greater than 0");
            }
        }
        _mintBatch(to, ids, amounts, data);
    }

    function openEditionMint(uint256 amount) public payable {
        require(amount > 0, "Amount must be greater than 0");
        numberMinted[_msgSender()] += amount;
        require(
            numberMinted[_msgSender()] <= maxPerWallet,
            "Max per wallet exceeded"
        );
        require(block.timestamp <= oeEndDate, "Open edition minting has ended");
        _mint(_msgSender(), 0, amount, "");
    }

    /*//////////////////////////////////////////////////////////////
                                 LOGIC
    //////////////////////////////////////////////////////////////*/

    function _afterTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    ) internal virtual override {
        if (from == address(0)) {
            return;
        }

        if (to == address(0)) {
            return;
        }

        uint256[] memory idsToMint = new uint256[](ids.length);
        uint256[] memory amountsToMint = new uint256[](ids.length);
        uint256[] memory idsToBurn = new uint256[](ids.length);
        uint256[] memory amountsToBurn = new uint256[](ids.length);

        uint256 idsLength = ids.length;
        for (uint256 i = 0; i < idsLength; i++) {
            if (ids[i] >= 79) {
                continue;
            }

            idsToBurn[i] = ids[i];

            uint256 amount = amounts[i];
            amountsToBurn[i] = amount;

            uint256 mintCount = 0;
            for (uint256 j = 0; j < amount; j++) {
                mintCount += _roulette(to, ids[i]);
            }

            idsToMint[i] = ids[i] + 1;
            amountsToMint[i] = mintCount;
        }

        _burnBatch(to, idsToBurn, amountsToBurn);
        _mintBatch(to, idsToMint, amountsToMint, "");
    }

    function _roulette(address to, uint256 id) private view returns (uint256) {
        uint256 _hash = uint256(blockhash(block.number - 1)) +
            uint256(uint160(to)) +
            id;
        LibPRNG.PRNG memory prng;
        LibPRNG.seed(prng, _hash);
        uint256 randomResult = LibPRNG.uniform(prng, 1000);
        if (randomResult < 500) {
            return 0;
        } else {
            return 1;
        }
    }

    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string.concat(super.uri(id), id.toString());
    }
}