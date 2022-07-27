// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

import "./ERC1155Base.sol";
import "../common/EquitySplitter.sol";

contract HouseOfBandits is ERC1155Base, EquitySplitter {
    uint8 constant MASTER = 0;
    uint8 constant HOUSE = 1;

    uint16 constant MAX_SUPPLY_MASTER = 1000;
    uint16 constant MAX_SUPPLY_HOUSE = 3500;

    uint256 public ogMintStartTime;
    uint256 public ogMintEndTime;
    uint256 public alphalistMintStartTime;
    uint256 public alphalistMintEndTime;
    uint256 public publicRaffleMintStartTime;
    uint256 public publicRaffleMintEndTime;

    struct KeyHolder {
      address walletAddress;
      uint256 numMaster;
      uint256 numHouse;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(_uri) MintingBase(0.123 ether) {
        name_ = _name;
        symbol_ = _symbol;
    }

    function setMintingWindows(
        uint256 _ogMintStartTime,
        uint256 _ogMintEndTime,
        uint256 _alphalistMintStartTime,
        uint256 _alphalistMintEndTime,
        uint256 _publicSaleMintStartTime,
        uint256 _publicSaleMintEndTime
    ) external onlyOwner {
        require(
            _publicSaleMintStartTime > _alphalistMintStartTime &&
                _alphalistMintStartTime > _ogMintStartTime &&
                _ogMintEndTime > _ogMintStartTime &&
                _alphalistMintEndTime > _alphalistMintStartTime &&
                _publicSaleMintEndTime > _publicSaleMintStartTime,
            "Invalid minting windows"
        );

        ogMintStartTime = _ogMintStartTime;
        ogMintEndTime = _ogMintEndTime;
        alphalistMintStartTime = _alphalistMintStartTime;
        alphalistMintEndTime = _alphalistMintEndTime;
        publicRaffleMintStartTime = _publicSaleMintStartTime;
        publicRaffleMintEndTime = _publicSaleMintEndTime;
    }

    function teamMint(
        address _address,
        uint16 _amountMaster,
        uint16 _amountHouse
    ) external onlyOwner whenNotPaused {
        require(
            totalSupply(HOUSE) + _amountHouse <= MAX_SUPPLY_HOUSE &&
                totalSupply(MASTER) + _amountMaster <= MAX_SUPPLY_MASTER,
            "Max supply reached"
        );

        _mint(_address, MASTER, _amountMaster, "");
        _mint(_address, HOUSE, _amountHouse, "");
    }

    function ogMint(
        uint8 _amountMaster,
        uint8 _amountHouse
    )
        external
        payable
        whenNotPaused
        mintingIsOpen(ogMintStartTime, ogMintEndTime, "OG")
    {
        _mintTokens(msg.sender, _amountMaster, _amountHouse);
    }

    function alphalistMint(
        uint8 _amountMaster,
        uint8 _amountHouse
    )
        external
        payable
        whenNotPaused
        mintingIsOpen(alphalistMintStartTime, alphalistMintEndTime, "Alphalist")
    {
        _mintTokens(msg.sender, _amountMaster, _amountHouse);
    }

    function publicMint(uint8 _amountMaster, uint8 _amountHouse)
        external
        payable
        whenNotPaused
    {
        _mintTokens(msg.sender, _amountMaster, _amountHouse);
    }

    function ownerMint(address to, uint8 _amountMaster, uint8 _amountHouse) external onlyOwner {
        uint256 totalAmount = _amountMaster + _amountHouse;
        require(totalAmount != 0, "Invalid amount of keys");
        require(
            totalSupply(HOUSE) + _amountHouse <= MAX_SUPPLY_HOUSE &&
                totalSupply(MASTER) + _amountMaster <= MAX_SUPPLY_MASTER,
            "Max supply reached"
        );
        if (_amountMaster > 0) {
            _mintToken(to, MASTER, _amountMaster);
        }

        if (_amountHouse > 0) {
            _mintToken(to, HOUSE, _amountHouse);
        }
    }

    function runAirDrop(KeyHolder[] calldata _holders) external onlyOwner {
        require(_holders.length != 0);

        for (uint256 i = 0; i < _holders.length; i++){
          KeyHolder memory holder = _holders[i];

          _mint(holder.walletAddress, MASTER, holder.numMaster, "");
          _mint(holder.walletAddress, HOUSE, holder.numHouse, "");
          
        }
    }

    function _mintTokens(address to, uint8 _amountMaster, uint8 _amountHouse) private nonReentrant {
        uint256 totalAmount = _amountMaster + _amountHouse;
        require(totalAmount != 0, "Invalid amount of keys");
        require(
            totalSupply(HOUSE) + _amountHouse <= MAX_SUPPLY_HOUSE &&
                totalSupply(MASTER) + _amountMaster <= MAX_SUPPLY_MASTER,
            "Max supply reached"
        );
        require(
            msg.value >= totalAmount * mintPrice,
            "Invalid amount of funds sent"
        );

        if (_amountMaster > 0) {
            _mintToken(to, MASTER, _amountMaster);
        }

        if (_amountHouse > 0) {
            _mintToken(to, HOUSE, _amountHouse);
        }

    }

    function _mintToken(address to, uint8 _tokenId, uint8 _amount) private {
        _mint(to, _tokenId, _amount, "");
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "Token does not exist");

        return
            string(
                abi.encodePacked(super.uri(_id), Strings.toString(_id), ".json")
            );
    }
}