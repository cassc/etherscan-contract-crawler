// SPDX-License-Identifier: MIT
// Author: ClubCards
// Developed by Max J. Rux
// Dev Twitter: @Rux_eth

pragma solidity ^0.8.7;

// openzeppelin imports
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// local imports
import "../interfaces/IClubCards.sol";
import "./CCEditions.sol";

contract ClubCards is ReentrancyGuard, CCEditions, IClubCards {
    using Address for address;
    using Strings for uint256;
    string public constant name = "ClubCards";
    string public constant symbol = "CC";
    string private conURI;

    uint256 private _maxMint = 10;

    bool private _allStatus = false;

    address private dev;

    constructor(address _dev) ERC1155("") {
        dev = _dev;
    }

    function mintCard(uint256 numMints, uint256 waveId)
        external
        payable
        override
        nonReentrant
    {
        prepMint(false, numMints, waveId);
        uint256 ti = totalSupply();
        if (numMints == 1) {
            _mint(_msgSender(), ti, 1, abi.encodePacked(waveId.toString()));
        } else {
            uint256[] memory mints = new uint256[](numMints);
            uint256[] memory amts = new uint256[](numMints);
            for (uint256 i = 0; i < numMints; i++) {
                mints[i] = ti + i;
                amts[i] = 1;
            }
            _mintBatch(
                _msgSender(),
                mints,
                amts,
                abi.encodePacked(waveId.toString())
            );
        }
        _checkReveal(waveId);
        delete ti;
    }

    function whitelistMint(
        uint256 numMints,
        uint256 waveId,
        uint256 nonce,
        uint256 timestamp,
        bytes calldata signature
    ) external payable override nonReentrant {
        prepMint(true, numMints, waveId);
        address sender = _msgSender();
        address recovered = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(
                keccak256(
                    abi.encode(sender, numMints, waveId, nonce, timestamp)
                )
            ),
            signature
        );
        require(
            recovered == admin() || recovered == owner(),
            "Not authorized to mint"
        );
        uint256 ti = totalSupply();
        if (numMints == 1) {
            _mint(_msgSender(), ti, 1, abi.encodePacked((waveId.toString())));
        } else {
            uint256[] memory mints = new uint256[](numMints);
            uint256[] memory amts = new uint256[](numMints);
            for (uint256 i = 0; i < numMints; i++) {
                mints[i] = ti + i;
                amts[i] = 1;
            }
            _mintBatch(
                _msgSender(),
                mints,
                amts,
                abi.encodePacked(waveId.toString())
            );
        }
        _checkReveal(waveId);
        delete ti;
    }

    // claim txs will revert if any tokenids are not claimable
    function claim(
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        uint256 nonce,
        uint256 timestamp,
        bytes memory signature
    ) external payable override nonReentrant {
        address sender = _msgSender();
        address recovered = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(
                keccak256(
                    abi.encode(sender, tokenIds, amounts, nonce, timestamp)
                )
            ),
            signature
        );
        require(
            tokenIds.length > 0 && tokenIds.length == amounts.length,
            "Array lengths are invalid"
        );
        require(
            recovered == admin() || recovered == owner(),
            "Not authorized to claim"
        );

        _mintBatch(sender, tokenIds, amounts, "");
        delete recovered;
        delete sender;
    }

    function manualSetBlock(uint256 waveId) external onlyTeam {
        _setWaveStartIndexBlock(waveId);
    }

    function setAllStatus(bool newAllStatus) external onlyTeam {
        _allStatus = newAllStatus;
    }

    function setContractURI(string memory newContractURI) external onlyTeam {
        conURI = newContractURI;
    }

    function withdraw() external payable onlyOwner {
        uint256 _each = address(this).balance / 100;
        require(payable(owner()).send(_each * 85));
        require(payable(dev).send(_each * 15));
    }

    function allStatus() public view override returns (bool) {
        return _allStatus;
    }

    function uri(uint256 id)
        public
        view
        override(ERC1155, IClubCards)
        returns (string memory)
    {
        return _getURI(id);
    }

    function contractURI() public view override returns (string memory) {
        return conURI;
    }

    function prepMint(
        bool privateSale,
        uint256 numMints,
        uint256 waveId
    ) private {
        require(_waveExists(waveId), "Wave does not exist");
        (
            ,
            uint256 MAX_SUPPLY,
            ,
            uint256 price,
            ,
            ,
            bool status,
            bool whitelistStatus,
            uint256 circSupply,
            ,

        ) = getWave(waveId);
        require(whitelistStatus == privateSale, "Not authorized to mint");
        require(allStatus() && status, "Sale is paused");
        require(msg.value >= price * numMints, "Not enough ether sent");
        require(numMints <= _maxMint && numMints > 0, "Invalid mint amount");
        require(
            numMints + circSupply <= MAX_SUPPLY,
            "New mint exceeds maximum supply allowed for wave"
        );
    }
}