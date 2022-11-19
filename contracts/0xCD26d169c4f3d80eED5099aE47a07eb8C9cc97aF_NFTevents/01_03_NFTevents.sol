// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTevents is Ownable {
    mapping(address => bool) private whitelistedBrand;
    event Transfer(
        address indexed contractAddress,
        address indexed _from,
        address indexed _to,
        uint256 _tokenId,
        string _brandName
    );
    event Approval(
        address indexed contractAddress,
        address indexed _owner,
        address indexed _to,
        uint256 _tokenId,
        string _brandName
    );
    event ApprovalForAll(
        address indexed contractAddress,
        address indexed _owner,
        address indexed _to,
        bool _approved,
        string _brandName
    );
    modifier onlyWhitelisted() {
        require(
            whitelistedBrand[msg.sender] == true,
            "Events: Caller not whitelisted!"
        );
        _;
    }

    function whitelistBrandContract(address _address) public onlyOwner {
        require(
            whitelistedBrand[_address] == false,
            "Events: Brand already whitelisted!"
        );
        whitelistedBrand[_address] = true;
    }

    function removeWhitelistBrandContrac(address _address) public onlyOwner {
        require(whitelistedBrand[_address] == true, "Brand does not Exists!");
        whitelistedBrand[_address] = false;
    }

    function transferEvent(
        address _from,
        address _to,
        uint256 _tokenId,
        string memory _brandName
    ) public onlyWhitelisted {
        emit Transfer(msg.sender, _from, _to, _tokenId, _brandName);
    }

    function approvalForAllEvent(
        address _owner,
        address _to,
        bool _approved,
        string memory _brandName
    ) public onlyWhitelisted {
        emit ApprovalForAll(msg.sender, _owner, _to, _approved, _brandName);
    }

    function approvalEvent(
        address _owner,
        address _to,
        uint256 _tokenId,
        string memory _brandName
    ) public onlyWhitelisted {
        emit Approval(msg.sender, _owner, _to, _tokenId, _brandName);
    }

    function checkIfWhitelisted(address _address) public view returns (bool) {
        return whitelistedBrand[_address];
    }
}