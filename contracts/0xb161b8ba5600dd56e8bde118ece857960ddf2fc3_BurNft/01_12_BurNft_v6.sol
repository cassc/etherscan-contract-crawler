// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

contract BurNft is ERC721, Ownable {
    using Strings for uint256;

    uint256 constant private MAX_SUPPLY = 1559;

    uint256 private costOfZeroCalldata = 4;
    uint256 private costOfNonZeroCalldata = 16;
    uint256 private gasCompensationFunctionCall = 21000;
    uint256 private gasCompensationUnchanged = 2800;
    uint256 private gasCompensationZeroing = 4800;

    uint256 private gasCompensationApprovePlusToZero = 10096;
    uint256 private gasCompensationApprovePlusNotToZero = 7915;
    uint256 private gasCompensationSafeTransferNoDataPlusToZero = 8052;
    uint256 private gasCompensationSafeTransferNoDataPlusNotToZero = 7970;
    uint256 private gasCompensationSafeTransferWithDataPlusToZero = 8427;
    uint256 private gasCompensationSafeTransferWithDataPlusNotToZero = 8346;
    uint256 private gasCompensationTransferPlusToZero = 8075;
    uint256 private gasCompensationTransferPlusNotToZero = 7993;
    uint256 private gasCompensationMinnt = 27020;

    uint256 public totalSupply; 

    mapping(uint256 => uint256) private lastEthBurned;
    mapping(uint256 => uint256) public lastBaseFee;
    mapping(uint256 => uint256) public lastGasSpent;
    mapping(uint256 => uint256) private previousGasSpent;

    string private baseUri;

    bool public enabled;

    error SendToOwner();
    error NotOwnerOrApproved();
    error NotFound(uint256 id);
    error TooMuchData();
    error BadPrice();
    error MaxSupply();
    error Disabled();
    error TransferError();

    constructor(string memory uri, address owner) ERC721("BURNFT", "BurNft") {
        baseUri = uri;
        transferOwnership(owner);
    }

    function ethBurned(uint256 tokenId) public view returns (uint256) {
        return lastEthBurned[tokenId] + (lastBaseFee[tokenId] * (lastGasSpent[tokenId] - ((lastGasSpent[tokenId] == previousGasSpent[tokenId])?gasCompensationUnchanged:0)));
    }

    function price() public view returns (uint256) {
        if (totalSupply <= 1500) {
            return ((totalSupply/100) * 0.01 ether);
        }
        return 0.1559 ether;
    }

    //Gas burning functions with tokenId
    function approve(address to, uint256 tokenId) public override {
        uint256 initialGas = gasleft();

            uint256 parameterGas = _calcCalldataGas(_msgData(), costOfZeroCalldata, costOfNonZeroCalldata);

            lastEthBurned[tokenId] = ethBurned(tokenId);
            lastBaseFee[totalSupply] = block.basefee;
            previousGasSpent[tokenId] = lastGasSpent[tokenId];

            address owner = ERC721.ownerOf(tokenId);
            if(to == owner) { revert SendToOwner(); }
            if(_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) { revert NotOwnerOrApproved(); }

            bool approvedToZero = (getApproved(tokenId) != address(0) && to == address(0));

            _approve(to, tokenId);

        if (approvedToZero) {
            uint256 gasSpent = parameterGas + (initialGas - gasleft());
            lastGasSpent[tokenId] = gasCompensationFunctionCall + gasCompensationApprovePlusToZero - gasCompensationZeroing + gasSpent;   
        } else {
            uint256 gasSpent = parameterGas + (initialGas - gasleft());
            lastGasSpent[tokenId] = gasCompensationFunctionCall + gasCompensationApprovePlusNotToZero + gasSpent;   
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        uint256 initialGas = gasleft();

            uint256 parameterGas = _calcCalldataGas(_msgData(), costOfZeroCalldata, costOfNonZeroCalldata);

            lastEthBurned[tokenId] = ethBurned(tokenId);
            lastBaseFee[totalSupply] = block.basefee;
            previousGasSpent[tokenId] = lastGasSpent[tokenId];

            uint256 zeroing;
            if (balanceOf(from) == 1) { zeroing += gasCompensationZeroing; }
            if (getApproved(tokenId) != address(0)) { zeroing += gasCompensationZeroing; }

            if(!_isApprovedOrOwner(_msgSender(), tokenId)) { revert NotOwnerOrApproved(); }
            _safeTransfer(from, to, tokenId, "");

        if (zeroing > 0) {
            uint256 gasSpent = parameterGas + (initialGas - gasleft());
            lastGasSpent[tokenId] = gasCompensationFunctionCall + gasCompensationSafeTransferNoDataPlusToZero - zeroing + gasSpent;   
        } else {
            uint256 gasSpent = parameterGas + (initialGas - gasleft());
            lastGasSpent[tokenId] = gasCompensationFunctionCall + gasCompensationSafeTransferNoDataPlusNotToZero  + gasSpent;   
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        uint256 initialGas = gasleft();

            uint256 parameterGas = _calcCalldataGas(_msgData(), costOfZeroCalldata, costOfNonZeroCalldata);
            parameterGas += _compensateCalldataDataGas(data);            

            lastEthBurned[tokenId] = ethBurned(tokenId);
            lastBaseFee[totalSupply] = block.basefee;
            previousGasSpent[tokenId] = lastGasSpent[tokenId];

            uint256 zeroing;
            if (balanceOf(from) == 1) { zeroing += gasCompensationZeroing; }
            if (getApproved(tokenId) != address(0)) { zeroing += gasCompensationZeroing; }

            if(!_isApprovedOrOwner(_msgSender(), tokenId)) { revert NotOwnerOrApproved(); }
            _safeTransfer(from, to, tokenId, data);

        if (zeroing > 0) {
            uint256 gasSpent = parameterGas + (initialGas - gasleft());
            lastGasSpent[tokenId] = gasCompensationFunctionCall + gasCompensationSafeTransferWithDataPlusToZero - zeroing + gasSpent;   
        } else {
            uint256 gasSpent = parameterGas + (initialGas - gasleft());
            lastGasSpent[tokenId] = gasCompensationFunctionCall + gasCompensationSafeTransferWithDataPlusNotToZero  + gasSpent;   
        }
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        uint256 initialGas = gasleft();

            uint256 parameterGas = _calcCalldataGas(_msgData(), costOfZeroCalldata, costOfNonZeroCalldata);

            lastEthBurned[tokenId] = ethBurned(tokenId);
            lastBaseFee[totalSupply] = block.basefee;
            previousGasSpent[tokenId] = lastGasSpent[tokenId];

            uint256 zeroing;
            if (balanceOf(from) == 1) { zeroing += gasCompensationZeroing; }
            if (getApproved(tokenId) != address(0)) { zeroing += gasCompensationZeroing; }

            if(!_isApprovedOrOwner(_msgSender(), tokenId)) { revert NotOwnerOrApproved(); }
            _transfer(from, to, tokenId);

        if (zeroing > 0) {
            uint256 gasSpent = parameterGas + (initialGas - gasleft());
            lastGasSpent[tokenId] = gasCompensationFunctionCall + gasCompensationTransferPlusToZero - zeroing + gasSpent;   
        } else {
            uint256 gasSpent = parameterGas + (initialGas - gasleft());
            lastGasSpent[tokenId] = gasCompensationFunctionCall + gasCompensationTransferPlusNotToZero  + gasSpent;   
        }
    }

    function mint() external payable {
        uint256 initialGas = gasleft();

            if (!enabled) { revert Disabled(); }
            if (msg.value != price()) { revert BadPrice(); }
            if (totalSupply >= MAX_SUPPLY) { revert MaxSupply(); }

            totalSupply += 1;
            _safeMint(msg.sender, totalSupply);

            lastBaseFee[totalSupply] = block.basefee;

        uint256 gasSpent = initialGas - gasleft();
        lastGasSpent[totalSupply] = gasCompensationFunctionCall + gasCompensationMinnt + gasSpent;
    }



    //Uri settings
    function tokenURI(uint256 id) public view override returns (string memory) {
        if (!_exists(id)) { revert NotFound(id); }
        return string(abi.encodePacked(baseUri, id.toString()));
    }

    function setBaseURI(string memory newUri) external onlyOwner {
        baseUri = newUri;
    }



    //Owner Functions
    function changeGasSettings(uint256 setting, uint256 value) external onlyOwner {
        if (setting == 1) { costOfZeroCalldata = value; return; }
        if (setting == 2) { costOfNonZeroCalldata = value; return; }
        if (setting == 3) { gasCompensationFunctionCall = value; return; }
        if (setting == 4) { gasCompensationZeroing = value; return; }
        if (setting == 5) { gasCompensationApprovePlusToZero = value; return; }
        if (setting == 6) { gasCompensationApprovePlusNotToZero = value; return; }
        if (setting == 7) { gasCompensationSafeTransferNoDataPlusToZero = value; return; }
        if (setting == 8) { gasCompensationSafeTransferNoDataPlusNotToZero = value; return; }
        if (setting == 9) { gasCompensationSafeTransferWithDataPlusToZero = value; return; }
        if (setting == 10) { gasCompensationSafeTransferWithDataPlusNotToZero = value; return; }
        if (setting == 11) { gasCompensationTransferPlusToZero = value; return; }
        if (setting == 12) { gasCompensationTransferPlusNotToZero = value; return; }
        if (setting == 13) { gasCompensationMinnt = value; return; }        
    }

    function setEnable(bool b) external onlyOwner {
        enabled = b;
    }

    function withdraw() external onlyOwner {
        (bool transfer,) = payable(owner()).call{value: address(this).balance}("");
        if (!transfer) { revert TransferError(); }
    }



    //Calldata calculation
    function _calcCalldataGas(bytes memory b, uint256 costOfZero, uint256 costOfNonZero) internal pure returns (uint256 gas) {
        for (uint i=0; i < b.length; i++) {
            gas += (b[i] == 0)?costOfZero:costOfNonZero;
        }
        return gas;
    }

    function _compensateCalldataDataGas(bytes memory data) internal pure returns (uint256 gas) {
        if (data.length > 0) {
            uint256 bytesLength = ((data.length-1)/32);
            if (bytesLength >= 128) { revert TooMuchData(); }

            gas += (bytesLength+1)*6;
            uint8[35] memory increment = [16,25,33,39,44,49,53,57,61,65,69,72,75,78,81,84,87,89,92,95,97,100,102,104,107,109,111,113,115,117,119,121,123,125,127];
            for (uint256 i=0; i<increment.length; i++) {
                if (bytesLength >= increment[i]) {
                    gas++;
                } else {
                    break;
                }
            }
        }
        return gas;
    }
}