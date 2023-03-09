// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDHController {
    struct UserDHShare {
        uint256 totalDH25Share;
        uint256 userDH25Share;
        // Sale for DH75
        address[] sales;
        // Total DH75 share for each sale
        uint256[] totalDH75Shares;
        // User DH75 share for each sale
        uint256[] userDH75Shares;
        bool isRegistered;
    }
    
    struct DistributionTimeline {
        uint256 registrationStart;
        uint256 start;
        uint256 end;
    }
    
    function isRegistration() external view returns (bool);
    
    function isClaiming() external view returns (bool);
    
    function getTimeline(uint256 distrIdx) external view returns (DistributionTimeline memory);
    
    function getRegistrants(uint256 distrIdx) external view returns (address[] memory);
    
    function register() external;
    
    // Returns: DH25 total share, DH75 sales, DH75 total share per sale
    function getTotalShares()
    external
    view
    returns (
        uint256,
        address[] memory,
        uint256[] memory
    );
    
    // Returns: total DH25 share, sale addresses, sale DH75 shares
    function getUserDHShares(address account) external view returns (UserDHShare memory);
}