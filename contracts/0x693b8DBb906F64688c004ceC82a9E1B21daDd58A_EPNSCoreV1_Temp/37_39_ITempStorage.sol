pragma solidity >=0.6.0 <0.7.0;

interface ITempStorage {
  /**
   * @notice Allows Core Contract to mark channel addresses with complete adjustments as TRUE.
   *
   * @param _channelAddress address of the channel to be flagged
  **/
  function setChannelAdjusted(address _channelAddress) external;
  /**
   * @notice returns the status of adjustement for a given channel address
   *
   * @param _channelAddress address of the channel to be flagged
  **/
  function isChannelAdjusted(address _channelAddress) external view returns(bool);

}