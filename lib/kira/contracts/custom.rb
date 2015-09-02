class ID
  def self.valid?(val)
    val.is_a?(String) && val.to_s.size == 32
  end
end


class Token
  def self.valid?(val)
    val.is_a?(String) && val.to_s.size == 32
  end
end
