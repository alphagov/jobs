module AssetHelpers

  def asset_path(asset_name)
    File.join(Rails.root, 'test', 'assets', asset_name)
  end

  def asset_contents(asset_name)
    File.read(asset_path(asset_name))
  end

end