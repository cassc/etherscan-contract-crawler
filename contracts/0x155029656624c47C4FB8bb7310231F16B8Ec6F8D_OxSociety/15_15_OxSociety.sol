// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/OxSociety.sol";

contract $OxSociety is OxSociety {
    constructor() {}

    function $_checkOwner() external view {
        return super._checkOwner();
    }

    function $_transferOwnership(address newOwner) external {
        return super._transferOwnership(newOwner);
    }

    function $_safeTransferFrom(address from,address to,uint256 id,uint256 amount,bytes calldata data) external {
        return super._safeTransferFrom(from,to,id,amount,data);
    }

    function $_safeBatchTransferFrom(address from,address to,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external {
        return super._safeBatchTransferFrom(from,to,ids,amounts,data);
    }

    function $_setURI(string calldata newuri) external {
        return super._setURI(newuri);
    }

    function $_mint(address to,uint256 id,uint256 amount,bytes calldata data) external {
        return super._mint(to,id,amount,data);
    }

    function $_mintBatch(address to,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external {
        return super._mintBatch(to,ids,amounts,data);
    }

    function $_burn(address from,uint256 id,uint256 amount) external {
        return super._burn(from,id,amount);
    }

    function $_burnBatch(address from,uint256[] calldata ids,uint256[] calldata amounts) external {
        return super._burnBatch(from,ids,amounts);
    }

    function $_setApprovalForAll(address owner,address operator,bool approved) external {
        return super._setApprovalForAll(owner,operator,approved);
    }

    function $_beforeTokenTransfer(address operator,address from,address to,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external {
        return super._beforeTokenTransfer(operator,from,to,ids,amounts,data);
    }

    function $_afterTokenTransfer(address operator,address from,address to,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external {
        return super._afterTokenTransfer(operator,from,to,ids,amounts,data);
    }

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }
}