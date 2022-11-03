// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./Restricted.sol";

contract PastelAlpha is ERC1155Supply, Restricted {

    using Counters for Counters.Counter;

    enum PeriodStatus { 
        waiting,
        whitelist
    }

    struct Period {
        uint id;
        uint cost;
        uint supply;
        uint expiry;
        bytes32 merkleRoot;
        PeriodStatus status;
    }

    string public name;
    string public symbol;   

    uint public PeriodId;
    Counters.Counter public PeriodCount;

    mapping (uint => mapping(address => bool)) Minted;
    mapping (uint => Period) public Periods;
    event TokenMinted (uint indexed idx, address indexed to);

    modifier validatePeriodId(
        uint periodId
    ) {
        require(periodId > 0 && periodId <= PeriodCount.current(),
            "error: period id < 0 or > current periods count"
        );
        _;
    }     

    modifier validateSupply (
        uint periodId,
        uint supply
    ) {
        require(totalSupply(periodId) <= supply, 
            "error: maximum supply < total minted tokens"
        );
        _;
    }   

    modifier validateMint (

    ) {
        require(msg.sender == tx.origin, 
            "error: can't mint under contract address"
        );
        require(Periods[PeriodId].cost == msg.value, 
            "error: invalid value"
        );
        require(Periods[PeriodId].status == PeriodStatus.whitelist, 
            "error: can't mint yet"
        );
        require(!Minted[PeriodId][msg.sender], 
            "error: already minted"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory baseUri
    ) ERC1155(baseUri) {
        name = _name;
        symbol = _symbol;
        transferOwnership(tx.origin);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint[] memory ids,
        uint[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        if (from != address(0) && to != address(0)) {
            for (uint i; i < ids.length;) {
                uint id = ids[i];
                require(Periods[id].expiry > block.timestamp,
                    "error: token is expired."
                );
                unchecked {
                    i++;
                }
            }
        }
    }  

    function createPeriod(
        uint cost,
        uint supply,
        bytes32 merkleRoot
    ) external restrictToAdmins {
        require(supply > 0, 
            "error: maximum supply < 0"
        );

        PeriodCount.increment();

        uint periodId = PeriodCount.current();
        Periods[periodId] = Period(
            periodId,
            cost,
            supply,
            block.timestamp + 360 days,
            merkleRoot,
            PeriodStatus.waiting
        );

        PeriodId = periodId;
    }

    function editPeriod(
        uint periodId,
        uint cost,
        uint supply,
        uint expiry,
        bytes32 merkleRoot
    ) external restrictToAdmins validatePeriodId(periodId) {
        Periods[periodId] = Period(
            periodId,
            cost,
            supply,
            expiry,
            merkleRoot,
            PeriodStatus.waiting
        );
    }

    function editSupply(
        uint periodId,
        uint supply
    ) external restrictToAdmins validatePeriodId(periodId) validateSupply(periodId, supply) {
        Periods[periodId].supply = supply;
    }

    function editWhitelist(
        uint periodId,
        uint cost,
        bytes32 merkleRoot
    ) external restrictToAdmins validatePeriodId(periodId) {
        Periods[periodId].merkleRoot = merkleRoot;
        Periods[periodId].cost = cost;
    }

    function editStatus(
        uint periodId,
        PeriodStatus status
    ) external restrictToAdmins validatePeriodId(periodId) {
        Periods[periodId].status = status;
    }

    function setPeriod(
        uint periodId
    ) external restrictToAdmins validatePeriodId(periodId) {
        PeriodId = periodId;
    }

    function whitelistMint (
        bytes32[] calldata proof
    ) external payable validateMint() {
        bytes32 root = Periods[PeriodId].merkleRoot;
        bytes32 hash = keccak256(
            abi.encodePacked(
                PeriodId,
                msg.sender
            )
        );

        require(MerkleProof.verify(
            proof,
            root,
            hash
        ),
            "error: verification failed"
        );
        
        require(totalSupply(PeriodId) < Periods[PeriodId].supply,
            "error: period max supply reached"
        );

        unchecked {
            Minted[PeriodId][msg.sender] = true;
        }

        _mint(msg.sender, PeriodId, 1, "");
        emit TokenMinted(PeriodId, msg.sender);
    }

    function ownerMint(
        address[] calldata _addresses
    ) external onlyOwner {
        uint len = _addresses.length;
        require((totalSupply(PeriodId) + len) <= Periods[PeriodId].supply,
            "error: amount exceeds max supply"
        );
        for (uint i = 0; i < len;) {
            _mint(_addresses[i], PeriodId, 1, "");
            emit TokenMinted(PeriodId, _addresses[i]);
            unchecked {
                i++;
            }
        }
    }

    function uri (
        uint tokenId
    ) public view override returns (string memory) {
        require (exists(tokenId),
            "error: token does not exist"
        );
        return string(
            abi.encodePacked(
                super.uri(tokenId),
                Strings.toString(tokenId),
                ".json"
            )
        );
    }

    function setURI(
        string memory baseUri
    ) external onlyOwner {
        _setURI(baseUri);
    }

    function revoke(
        address from,
        address to,
        uint periodId,
        uint amount
    ) external restrictToAdmins {
        _safeTransferFrom(
            from,
            to,
            periodId,
            amount,
            ""
        );
    }

    function withdraw(

    ) external onlyOwner {
        (bool success, ) = owner().call{
            value: address(this).balance
        }("");

        require(success,
            "error: withdrawal failed"
        );
    }
}