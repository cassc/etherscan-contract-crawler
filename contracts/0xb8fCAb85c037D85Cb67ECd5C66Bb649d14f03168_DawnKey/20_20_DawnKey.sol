// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/DawnKey.sol";

contract XDawnKey is DawnKey {
    constructor(string memory uriBase, string memory _name, string memory _symbol, address efAddress, address vAddress, address cAddress, address _signerAddress) DawnKey(uriBase, _name, _symbol, efAddress, vAddress, cAddress, _signerAddress) {}

    function x_transferOwnership(address newOwner) external {
        return super._transferOwnership(newOwner);
    }

    function x_safeTransferFrom(address from,address to,uint256 id,uint256 amount,bytes calldata data) external {
        return super._safeTransferFrom(from,to,id,amount,data);
    }

    function x_safeBatchTransferFrom(address from,address to,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external {
        return super._safeBatchTransferFrom(from,to,ids,amounts,data);
    }

    function x_setURI(string calldata newuri) external {
        return super._setURI(newuri);
    }

    function x_mint(address to,uint256 id,uint256 amount,bytes calldata data) external {
        return super._mint(to,id,amount,data);
    }

    function x_mintBatch(address to,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external {
        return super._mintBatch(to,ids,amounts,data);
    }

    function x_burn(address from,uint256 id,uint256 amount) external {
        return super._burn(from,id,amount);
    }

    function x_burnBatch(address from,uint256[] calldata ids,uint256[] calldata amounts) external {
        return super._burnBatch(from,ids,amounts);
    }

    function x_setApprovalForAll(address owner,address operator,bool approved) external {
        return super._setApprovalForAll(owner,operator,approved);
    }

    function x_beforeTokenTransfer(address operator,address from,address to,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external {
        return super._beforeTokenTransfer(operator,from,to,ids,amounts,data);
    }

    function x_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function x_msgData() external view returns (bytes memory) {
        return super._msgData();
    }
}